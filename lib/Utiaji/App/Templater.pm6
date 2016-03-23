use Utiaji::App;
use Utiaji::Log;
use Utiaji::Template;

class Utiaji::App::Templater is Utiaji::App {
    has $.templates = Utiaji::Template.new;
    method BUILD {
        self.router.get('/hello', sub ($req, $res) {
            self.render: $res, template => "hello"
        });
        self.router.get('/hello/:person', sub ($req, $res, $/) {
            self.render: $res,
                template => "hello/person",
                template_params => { name => $<person> }
        });
    }
}
