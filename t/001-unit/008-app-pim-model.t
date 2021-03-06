use lib 'lib';
use lib 't/tlib';
use tlib;
use Test;
use Utiaji::Model::Pim;
use Utiaji::DB;
use Utiaji::Test;

clear-db;

my $pim = Utiaji::Model::Pim.new;

ok so $pim.cal, "pim has a calendar";
ok so $pim.wiki, "pim has a wiki";
ok so $pim.rolodex, "pim has a rolodex";

ok $pim.save(Day.new(date => '2016-01-02', text => "jan 2 day")), 'saved';
$pim.cal.load(:from<2016-01-02>,:to<2016-01-02>);
is $pim.cal.days.elems, 1, '1 day';
ok $pim.cal.align, 'align';

is $pim.cal.from.day-of-week, 7, 'align to sunday';
is $pim.cal.to.day-of-week, 6, 'last is saturday';

$pim.cal.load(focus => '2016-01-01');

my %init = $pim.cal.initial-state;
my %expect =
  data  => { "2016-01-02" => "jan 2 day" },
  first => [2015, 12, 27],
  month => 1,
  focus => '2016-01-01',
  year  => 2016;
is-deeply %init, %expect, 'initial data';

ok %init<first>:exists, 'first day';
ok %init<month>:exists, 'month';
ok %init<data>:exists, 'data';

my $day = Day.new( date => "2011-01-01", text => 'something @big');
ok $day.date.isa('Date'), 'coercion';
ok $pim.save($day), 'saved';

my $page = $pim.page("big");
is $page.name, 'big', 'saved and loaded page';
is $page.refs-in(date).elems, 1, '1 ref to this page';
is $page.refs-in(date)[0], 'date:2011-01-01', "the right day";

$page = Page.new(name => "foo", text => 'bar @baz');
ok $pim.save($page), 'saved wiki page';

my $empty = Page.new(name => "something");
ok $pim.save($empty), 'saved empty page';

$day = Day.new(date => "2011-01-01", text => 'something @small');
ok $pim.save($day), 'saved day';
$page = $pim.page("big");
is $page.refs-in(page).elems, 0, "no dates link to big anymore";

my $picnic = Page.new(name => 'picnic', text => 'bring @beer and @wine and @chips');
ok $pim.save($picnic), 'saved';

for <beer wine chips> -> $p {
    my $item = $pim.page($p);
    is $item.refs-in(page).elems, 1, "1 ref to $p";
    is $item.refs-in(page, :ids)[0], 'picnic', "link from picnic to $p";
}

my $rain = Page.new(name => 'picnic', text => 'rained out');
ok $pim.save($rain),' replaced page';
for <beer wine chips> -> $p {
    my $item = $pim.page($p);
    is $item.refs-in(page).elems, 0, "0 refs to $p from picnic";
}

my $face = Page.new(name => 'face', text => '😀');
ok $pim.save($face),' unicode face';
my $loaded = $pim.page('face');
ok $loaded, 'loaded face';
is $loaded.text, '😀', 'got unicode char';

my $card = Card.new(text => "Joe Schmoe\n10 Main st\nTownsville, CA 94530");
is $card.handle, 'joe-schmoe', 'made a handle automagically';
ok $pim.save($card), 'saved card';
my $h = $card.handle;
my $again = $pim.card($h);
is $again.text, "Joe Schmoe\n10 Main st\nTownsville, CA 94530", "loaded text";

my $r = Rolodex.new;

my @cards = $r.search("j");
ok @cards==1, 'One card searching for j';
is @cards[0].handle, 'joe-schmoe', 'got the right card';
is @cards[0].rep-ext{'handle'}, 'joe-schmoe', 'got rep-ext';

my @none = $r.search("ville");
ok @none==0, 'Only match name line';

ok $r.search("moe").elems==0, "only match start of words";
ok $r.search("Sc").elems==1, "only match start of words";
ok $r.search("J").elems==1, "only match start of words";

done-testing;

