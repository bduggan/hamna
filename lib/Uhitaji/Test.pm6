unit class Uhitaji::Test;

use HTTP::Tinyish;
use JSON::Fast;
use Uhitaji::Log;
use Test;

use Uhitaji::Server;

has %.res is rw;
has HTTP::Tinyish $.ua = HTTP::Tinyish.new;
has Uhitaji::Server $.server is rw = Uhitaji::Server.new;

method get-ok(Str $path) {
    %.res = $.ua.get($.server_url ~ $path);
    isnt %.res<status>, 599, "GET $path";
    self;
}

method status-is(Int $status) {
    is %.res<status>, $status, "status $status";
    self;
}

method content-is(Str $content) {
    my $printable = $content.subst("\n",'\\n',:g);
    is %.res<content>, $content, qq[Content is "$printable"];
    self;
}

method content-type-is(Str $content_type) {
    is %.res<headers><content-type>,
        "$content_type; charset=utf-8",
        "Content type $content_type";
    self;
}

multi method post-ok(Str $path, :$json) {
    %.res = $.ua.post($.server_url ~ $path,
        headers => "Content-type" => 'application/json',
        content => to-json( $json )
    );
    isnt %.res<status>, 599, "POST $path";
    self;
}

multi method post-ok(Str $path, :%headers, Str :$content ) {
    %.res = $.ua.post($.server_url ~ $path,
        headers => %headers,
        content => $content
    );
    isnt %.res<status>, 599, "POST $path";
    self;
}

multi method post-ok(Str $path) {
    %.res = $.ua.post($.server_url ~ $path);
    isnt %.res<status>, 599, "POST $path";
    self;
}

method json-is($json) {
    self.content-type-is('application/json');
    my $json_res;
    try {
        $json_res = from-json(%.res<content>);
        CATCH {
            diag %.res<content>;
            diag .message;
            .resume;
        }
    }
    is-deeply $json, $json_res, "JSON matches";
    self;
}

method server_url {
    $.server.url;
}

method start($app) {
    $.server = Uhitaji::Server.new(app => $app);
    $.server.start-fork;
    $.server.ping or error "Could not start server";
    self;
}

method stop {
    $!server.stop-fork;
}
