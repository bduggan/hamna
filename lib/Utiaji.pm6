use JSON::Fast;
use DBIish;

use Utiaji::App;
use Utiaji::DB;
use Utiaji::Log;


#my $db = DBIish.connect("Pg", database => %*ENV<PGDATABASE>);
my $db = Utiaji::DB.new;
# setup:
# createdb utiaji
# psql utiaji -c "create table kv(k varchar not null primary key, v jsonb)"

class Utiaji is Utiaji::App {
method BUILD {

    my regex piece { <-[ / ]>+ };

    self.routes = Utiaji::Routes.new;
    # Routing table.
    given (self.routes) {
        .get(rx{^ \/ $},
            sub ($req,$res) {
                self.render($res, text => 'Welcome to Utiaji.');
            }
        );

        .get(rx{^ \/get\/<key=piece> $},
            sub ($req,$res,$m) {
                $db.query('select v from kv where k=?', $m<key>)
                           or return self.render($res, status => 404);
                return self.render($res, :404status) unless $db.json;
                self.render($res, json => $db.json);
            }
        );

        .post(rx{^ \/set\/<key=piece> $},
            sub ($req,$res,$m) {
                my $key = $m<key>;
                my $json;
                my $errors;
                # TODO encapsulate
                try {
                    CATCH {
                        debug "error: { .message }";
                        $errors = .message;
                        .resume;
                    }
                    # chop removes trailling \0
                    $json = from-json($req.data.decode('UTF-8').chop);
                }
                if ($errors or !$json) {
                     trace "rendering error";
                     return self.render( $res,
                         status => 400,
                         json =>
                          { status => "fail",
                            reason => $errors // "Could not parse" }
                     );
                }

                $db.query(q[insert into kv (k,v) values (?, ?)], $key, to-json($json))
                    or return self.render($res,
                        json => { status => "fail", reason => $db.errors },
                        status => 409
                   );
                trace "rendering ok";
                self.render($res, json => { status => 'ok' } );
            }
        );

        .post(rx{^ \/del\/<key=piece> $},
            sub ($req,$res,$m) {
                my $errors;
                my $key = $m<key>;
                $errors = "";
                try {
                    CATCH {
                        $errors = .message;
                        .resume
                    }
                    my $sth = $db.db.prepare(q[delete from kv where k = ?]);
                    $sth.execute($key);
                }
                if ($errors) {
                    return self.render($res,
                        status => 400,
                        json => { status => "fail", reason => $errors, });
                }

                return self.render($res, json => { status => 'ok' });
            }
        );

    }
}
}
