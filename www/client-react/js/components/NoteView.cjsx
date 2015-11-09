React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Note} = require '../../../shared/aris.js'

exports.NoteView = React.createClass
  propTypes:
    onBack: T.func
    note:   T.instanceOf Note

  render: ->
    <div>
      <p><button type="button" onClick={@props.onBack}>Back</button></p>
      <p><img src={@props.note.photo_url} /></p>
      <p>{@props.note.description}</p>
      { for comment in @props.note.comments
          <div key={"comment-#{comment.comment_id}"}>
            <h4>{comment.user.display_name}, {comment.created.toLocaleString()}</h4>
            <p>{comment.description}</p>
          </div>
      }
    </div>
