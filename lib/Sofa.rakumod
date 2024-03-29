use v6;

use Sofa::Method;
use Sofa::Exception;

class Sofa:auth<github:jonathanstowe>:ver<0.0.1> does Sofa::Exception::Handler {
    use Sofa::UserAgent;
    use Sofa::Database;
    use Sofa::User;


    has Sofa::UserAgent $.ua is rw;
    has Int  $.port is rw = 5984;
    has Str  $.host is rw = 'localhost';
    has Bool $.secure = False;

    has Str $.username;
    has Str $.password;

    has Bool $.basic-auth;

    has Bool $!has-session;

    has Sofa::Database @.databases;

    method ua( --> Sofa::UserAgent ) is rw {
        if not $!ua.defined {
            $!ua = Sofa::UserAgent.new(host => $!host, port => $!port, secure => $!secure,);
            if self!use-basic-auth {
                $!ua.auth($!username, $!password);
            }
        }
        if self!requires-session {
            self.start-session;
        }
        $!ua;
    }

    method !got-auth( --> Bool ) {
        $!username.defined && $!password.defined;
    }

    method !use-basic-auth( --> Bool ) {
        self!got-auth && $!basic-auth;
    }

    method !requires-session() {
        self!got-auth() && not $!basic-auth && not $!has-session;
    }

    method start-session() {
        my %form = name => $!username, password => $!password;
        my $res = $!ua.post(path => '_session', :%form);
        if not $res.is-success {
            $!has-session = False;
            self!get-exception($res.code, '_session', "getting session", Sofa::Exception::Server).throw;
        }
        else {
            $!has-session = True;
        }
    }

    method !db-names() {
        my @db-names;
        my $response = self.ua.get(path => '_all_dbs');
        if $response.is-success {
            @db-names = $response.from-json.list;
        }
        @db-names;
    }

    method databases() {
        my @dbs = self!db-names;
        if @!databases.elems ne @dbs.elems {
            @!databases = ();
            for @dbs -> $name {
                @!databases.push: Sofa::Database.fetch(:$name, ua => self.ua);
            }
        }
        @!databases;
    }

    method create-database(Str $name) {
        my $db;
        if not @.databases.grep({ $_.name eq $name } ) {
            $db = Sofa::Database.create(:$name, ua => self.ua);
            @.databases.push: $db;
        }
        else {
            X::Sofa::DatabaseExists.new(:$name).throw;
        }
        $db;
    }

    method get-database(Str $name --> Sofa::Database ) {
        @.databases.grep({$_.name eq $name}).first;
    }

    has Sofa::Database $.user-db;
    method user-db( --> Sofa::Database ) {
        if not $!user-db.defined {
            $!user-db = self.get-database('_users');
        }
        $!user-db;
    }

    method users() {
        self.user-db.all-docs(:detail, type => Sofa::User).map(-> $d { $d.doc }).grep({ $_.sofa-document-id !~~ /^_design/});
    }

    proto method add-user(|c) { * }

    multi method add-user(Str :$name!, Str :$password, :@roles --> Sofa::User ) {
        my $user = Sofa::User.new(:$name, :$password, :@roles);
        self.add-user($user);
        $user;
    }

    multi method add-user(Sofa::User:D $user) {
        self.user-db.create-document($user.generate-id, $user);
    }

    method get-user(Str $name --> Sofa::User ) {
        my $id = Sofa::User.generate-id($name);
        self.user-db.get-document($id, Sofa::User);
    }

    method update-user(Sofa::User:D $user) {
        self.user-db.update-document($user);
    }

    proto method delete-user(|c) { * }

    multi method delete-user(Str $name) {
        my $user = self.get-user($name);
        self.delete-user($user);
    }

    multi method delete-user(Sofa::User:D $user) {
        self.user-db.delete-document($user);
    }

    method session() handles <is-admin> is sofa-item('Sofa::Session') { * }

    method statistics() is sofa-item('Sofa::Statistics') { * }

    method configuration() is sofa-item('Sofa::Config') { * }

    method server-details() is sofa-item('Sofa::Server') { * }
}
# vim: expandtab shiftwidth=4 ft=raku
