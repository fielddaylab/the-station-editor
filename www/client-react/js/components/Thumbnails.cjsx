React = require 'react/addons'
T = React.PropTypes
{Note} = require '../../../shared/aris.js'

exports.Thumbnails = React.createClass
  propTypes:
    notes: T.arrayOf T.instanceOf Note

  render: ->
    <div>
      { @props.notes.map (note) =>
          <a key={"thumb-#{note.note_id}"} href={"##{note.note_id}"}>
            <img src={note.thumb_url} />
          </a>
      }
    </div>

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.notes isnt nextProps.notes
