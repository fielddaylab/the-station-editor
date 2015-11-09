React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Note} = require '../../../shared/aris.js'
GoogleMap = require 'google-map-react'

exports.NoteMap = React.createClass
  propTypes:
    latitude:       T.number
    longitude:      T.number
    zoom:           T.number
    notes:          T.arrayOf T.instanceOf Note
    onBoundsChange: T.func

  render: ->
    note_ids =
      note.note_id for note in @props.notes
    max_note_id = Math.max(note_ids...)
    min_note_id = Math.min(note_ids...)
    <GoogleMap
      center={[@props.latitude, @props.longitude]}
      zoom={@props.zoom}
      onChildClick={(key, childProps) => window.location.hash = key[7..]}
      onChange={@props.onBoundsChange}>
      { for note in @props.notes
          age = (note.note_id - min_note_id) / (max_note_id - min_note_id)
          age_percent = "#{age * 100}%"
          color = "rgb(#{age_percent}, #{age_percent}, #{age_percent})"
          <div
            key={"marker-#{note.note_id}"}
            lat={note.latitude}
            lng={note.longitude}
            style={marginLeft: '-5px', marginTop: '-5px', width: '10px', height: '10px', backgroundColor: color, cursor: 'pointer'}
            />
      }
    </GoogleMap>

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.latitude isnt nextProps.latitude or
    @props.longitude isnt nextProps.longitude or
    @props.zoom isnt nextProps.zoom or
    @props.notes isnt nextProps.notes or
    @props.onBoundsChange isnt nextProps.onBoundsChange
    # is the onBoundsChange check necessary? doesn't seem to hurt performance
