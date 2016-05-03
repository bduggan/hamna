
['div','table','tbody','tr','th','td','span','textarea']
  .map(function(v) {
    eval( v + " = gen('" + v + "');");
});

var Cal = React.createClass({

    getInitialState: function() {
        return this.props.initial_data
    },
    dt: function(i) {
        // todo: cache
        return this.state.first.addDays(i)
    },
    edit: function(e) {
        var index = e.target.firstChild.id;
        if (typeof index === 'undefined' ) {
            return;
        }
        this.setState({ editing:index });
        console.log('edit cell',index);
    },
    cell: function(i) {
       var dt = this.dt(i);
       return [ span(
           {className:'dt', id: i}, dt.d()
                ), this.state.data[ dt.ymd() ] ];
    },
    editcell: function(i) {
        return textarea({defaultValue:this.state.data[this.dt(i).ymd()]});
    },
    cells: function(from,to) {
        var x = [];
        var e = this.state.editing;
        for (i=from;i<to;i++) {
            if (e==i) {
              x.push( this.editcell(i) );
            } else {
              x.push( this.cell(i) );
            }
        }
        return x;
    },
    handleChange: function(e) {
        // this.setState({ text: e.target.value } );
    },
    render: function() {
        return div(
            div( {className: 'text-center month'} , ( this.state.month + ' ' + this.state.year ) ),
            table( {className: 'cal', onClick: this.edit},
                tbody(
                  ...tr([
                        th( ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'] ),
                        td( this.cells(0,7)    ),
                        td( this.cells(14,21)  ),
                        td( this.cells(21,28)  ),
                        td( this.cells(28,35)  ),
                        td( this.cells(35,42)  ),
                      ])
                    )
                 )
            )
    }
});


