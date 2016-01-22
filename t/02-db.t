use v6;
use Test;
use DBIish;
use lib 'lib';

my $db = %*ENV<PGDATABASE>;
unless $db {
    skip-rest "Set PGDATABASE for database testing";
    exit;
}

diag "PGDATABASE=$db";

ok $db, 'PGDATABASE is set';

my $dbh = DBIish.connect("Pg", :database($db));

ok $dbh, "Made a database handle.";

my $sth = $dbh.prepare("select 42");

ok $sth, "Made a statement handle.";

ok $sth.execute, "Executed a statement.";

my $results = $sth.fetchall_arrayref();

ok $results, "Got results.";

is $results, 42, "Got the right results.";

ok $dbh.disconnect, "Disconnect.";

done-testing;

