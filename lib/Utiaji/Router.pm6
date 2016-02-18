use Utiaji::Log;

# Turns patterns for routes into regexes.

grammar Utiaji::Router {
    token TOP          { '/' <part> *%% '/' }
    token part         { <literal> || <placeholder> }
    token literal      { <[a..z]>+ }

    token placeholder  {
              <placeholder_word>
            | <placeholder_ascii_lc>
            | <placeholder_date> }
    token placeholder_word     { ':' <var> }
    token placeholder_ascii_lc { '_' <var> }
    token placeholder_date     { 'Δ' <var> } # delta : D*

    token var { <[a..z]>+ }
}

class Utiaji::RouterActions {
    method TOP($/)     {
        $/.make: q[ '/' ] ~ join q[ '/' ], map { .made }, $<part>;
    }
    method part($/)    {
        $/.make: $<literal>.made // $<placeholder>.made;
    }
    method placeholder($/){
        $/.make: $<placeholder_word>.made
              // $<placeholder_ascii_lc>.made
              // $<placeholder_date>.made}
    method placeholder_word($/)     { $/.make: "<" ~ $<var>.made ~ '=placeholder_word>'; }
    method placeholder_ascii_lc($/) { $/.make: "<" ~ $<var>.made ~ '=placeholder_ascii_lc>'; }
    method placeholder_date($/)     { $/.make: "<" ~ $<var>.made ~ '=placeholder_date>'; }

    method var($/)     {
        $/.make: ~$/;
    }
    method literal($/) {
        $/.make: ~$/;
    }
}

class Utiaji::Matcher {
    has Str $.pattern is rw;
    has %.captures is rw = {};
    has $.parser is rw;

    my regex placeholder_word     { [ \w | '-' ]+ }
    my regex placeholder_ascii_lc { [ <[a..z]> | <[0..9]> | '_' | '-' ]+ }
    my regex placeholder_date     { \d+ '-' \d+ '-' \d+ }

    method match(Str $path) is export {
        trace "Parsing $path";
        self.captures = {};
        $.parser //= Utiaji::Router.parse($.pattern,
            actions => Utiaji::RouterActions.new
        );
        trace "parsed $path using { $.pattern.gist } ";
        my $rex = $.parser.made;
        my $result = $path ~~ rx{ ^ <captured=$rex> $ };
        trace "result is { $result.gist }";
        my %h = $/.hash.clone;
        my %c = %h{'captured'}.hash;
        # TODO cleanup
        %c<placeholder_word>:delete;
        %c<placeholder_ascii_lc>:delete;
        %c<placeholder_date>:delete;
        return $result unless %c.elems > 0;
        for %c.kv -> $k, $v {
            %c{$k} = ~$v;
        }
        self.captures = %c;
        return $result;
    }
}
