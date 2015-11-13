React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Note} = require '../../../shared/aris.js'

exports.NoteView = React.createClass
  displayName: 'NoteView'

  propTypes:
    onBack:             T.func
    note:               T.instanceOf Note
    loggedIn:           T.bool
    newComment:         T.string
    onNewCommentChange: T.func
    onPostComment:      T.func

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
      { if @props.loggedIn
          <div>
            <p>
              <textarea value={@props.newComment}
                placeholder="Post a comment..."
                onChange={(e) => @props.onNewCommentChange e.target.value}
                style={width: '400px', height: '100px'} />
            </p>
            <p>
              <button type="button" onClick={@props.onPostComment}>
                Post Comment
              </button>
            </p>
          </div>
      }
    </div>
