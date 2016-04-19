#!/usr/bin/env perl6

use v6.c;

use Test;
use CheckSocket;

use Sofa;
use Sofa::User;

my $port = %*ENV<COUCH_PORT> // 5984;
my $host = %*ENV<COUCH_HOST> // 'localhost';

my Bool $test-changes = %*ENV<SOFA_TEST_CHANGES>:exists;

if !check-socket($port, $host) {
    plan 1;
    skip-rest "no couchdb available";
    exit;
}

my $sofa;

lives-ok { $sofa = Sofa.new(:$host, :$port) }, "can create an object";

if $sofa.is-admin {
    my @users;
    lives-ok { @users = $sofa.users }, "get the users";
    my $u-count = @users.elems;
    my $user;
    lives-ok { $user = Sofa::User.new(name => get-username(), password => 'zubzubzub'); }, "new user object";
    lives-ok { $sofa.add-user($user) }, "add-user";
    my $rev = $user.sofa-document-revision;
    ok $rev.defined, "got the revision";
    lives-ok { @users = $sofa.users }, "get the users";
    is @users.elems, $u-count + 1, "got one more user";
    $user.password = "newpassword";
    lives-ok { $sofa.update-user($user) }, "update the passsword";
    isnt $user.sofa-document-revision, $rev, "and the revision got updated";
    lives-ok { $sofa.delete-user($user) }, "delete the user";
    lives-ok { @users = $sofa.users }, "get the users";
    is @users.elems, $u-count, "got one less user";
}
else {
    skip "Need to be admin to test users";
}

sub get-username() {
    ('a' .. 'z').pick(8).join('');
}



done-testing;
# vim: expandtab shiftwidth=4 ft=perl6