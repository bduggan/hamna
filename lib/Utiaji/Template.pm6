unit class Utiaji::Template;
use Utiaji::Log;

has $.raw;
has $.parsed;

grammar parser {
    rule TOP {
     [ ^ '%-' [ $<signature>=[ \V+ ] ] \n ]?
     [    <line=statement>
        | <line=text>
     ] *
    }

    token ws { \h* }

    token statement {
        '%' [ <expression> | <comment> | <code> ] \n
    }

    token expression {
        '=' \V* }
    token comment {
        '#' \V* }
    token code {
        \V* }

    regex text {
        <!after '%'>
        [
            <piece=verbatim>
        |
         [ <inline-start>
            [ <piece=inline-code> | <piece=inline-expression> ]
          <inline-end>
         ]
        ]*
        $<cr> = [\n]
    }

    regex verbatim {
        [ <-[<\v]> | '<' <-[%\v]> ]+
    }

    token inline-code { <-[\v%]>+ }
    token inline-expression { '=' [ <-[\v%]> | '%' <!before '>'> ] + }

    token inline-start { '<%' }
    token inline-end   { '%>' }

}

class actions {
    method TOP($/) {
        my $head = ' sub (';
        $head ~= $<signature> ?? $<signature> !! ':%args';
        $head ~= ') { ' ~ "\n";
        $head ~=  'my @out = (); ';
        my @lines = grep { .defined }, map { .made }, $<line>;
        my $tail = ' return @out; } ';
        $/.make( join "\n", $head, @lines, $tail );
    }

    method text($/) {
        $/.make: [ ( map { .made }, $<piece> ), $<cr>, '@out.push: "\n";' ];
    }

    method inline-code($/) {
        $/.make: ~$/;
    }

    method inline-expression($/) {
        my $str = $/.subst( /^ '=' /,'');
        $/.make: "@out.push: $str;\n";
    }

    method verbatim($/) {
        $/.make: "@out.push: q[$/];\n";
    }

   method statement($/) {
        $/.make: $<expression>.made || $<code>.made;
    }

    method expression($/) {
        my $str = $/.subst(/^ '='/,'');
        $/.make: qq|@out.push: $str ~ "\n";\n|
    }

    method comment($/) {
        $/.make: Nil
    }

    method code($/) {
        $/.make: ~$/;
    }

    method signature($/) {
        my $str = $/.subst(/^ '-'/,'');
        $/.make: $str;
    }

}

multi method parse($!raw) {
    self.parse;
}

multi method parse {
    my $act = actions.new;
    my $raw = chomp($.raw) ~ "\n";
    my $p = parser.parse($raw, actions => $act) or do {
        error "did not parse $raw";
        return
    };
    use MONKEY-SEE-NO-EVAL;
    my $code = $p.made;
    trace "---code--";
    trace $code;
    trace "---------";
    $!parsed = EVAL $code;
    self;
}

method render(*%params) {
   self.parse unless $.parsed;
   return unless $!parsed;
   trace "sending params " ~ %params.perl;
   my $out = $!parsed(|%params).join("");
   $out.=chomp unless $!raw ~~ /\n $/;
   return $out;
}
