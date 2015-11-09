React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Tag} = require '../../../shared/aris.js'
{ImageUploader} = require './ImageUploader.js'
GoogleMap = require 'google-map-react'

exports.Uploader = React.createClass
  propTypes:
    description:   T.string
    tags:          T.arrayOf T.instanceOf Tag
    tag:           T.instanceOf Tag
    url:           T.string
    latitude:      T.number
    longitude:     T.number
    zoom:          T.number
    onChange:      T.func
    noteLatitude:  T.number
    noteLongitude: T.number

  getInitialState: ->
    draggingMarker: null

  render: ->
    <div>
      <input ref="description" type="text" value={@props.description}
        onChange={(e) => @props.onChange description: e.target.value} />
      <ImageUploader
        url={@props.url}
        onImageSelect={(url) => @props.onChange {url}}
        width="400px"
        height="400px"
      />
      <form>
        { @props.tags.map (tag) =>
            <p key={tag.tag_id}>
              <label>
                <input type="radio"
                  checked={@props.tag.tag_id is tag.tag_id}
                  onChange={=>
                    # React warns if you don't have this,
                    # even though we have onClick below...?
                  }
                  onClick={=> @props.onChange tag: tag}
                />
                { tag.tag }
              </label>
            </p>
        }
      </form>
      <div style={width: '500px', height: '500px'}>
        <GoogleMap
          center={[@props.latitude, @props.longitude]}
          zoom={@props.zoom}
          onChange={({center: {lat, lng}, zoom}) =>
            @props.onChange
              latitude: lat
              longitude: lng
              zoom: zoom
          }
          draggable={not @state.draggingMarker?}
          onChildMouseDown={(hoverKey, childProps, mouse) =>
            if hoverKey is 'note-location'
              @setState
                draggingMarker:
                  latitude: @props.noteLatitude
                  longitude: @props.noteLongitude
          }
          onChildMouseUp={(hoverKey, childProps, mouse) =>
            if hoverKey is 'note-location'
              @props.onChange
                noteLatitude: @state.draggingMarker.latitude
                noteLongitude: @state.draggingMarker.longitude
              @setState draggingMarker: null
          }
          onChildMouseMove={(hoverKey, childProps, mouse) =>
            if hoverKey is 'note-location' and @state.draggingMarker?
              @setState
                draggingMarker:
                  latitude: mouse.lat
                  longitude: mouse.lng
          }>
          <div
            key="note-location"
            lat={@state.draggingMarker?.latitude ? @props.noteLatitude}
            lng={@state.draggingMarker?.longitude ? @props.noteLongitude}
            style={marginLeft: '-10px', marginTop: '-10px', width: '20px', height: '20px', backgroundColor: 'red', cursor: 'pointer'}
            />
        </GoogleMap>
      </div>
      <p>
        <button type="button" onClick={=>}>
          Submit
        </button>
      </p>
      <p>
        <button type="button" onClick={=> window.location.hash = '#'}>
          Cancel
        </button>
      </p>
    </div>
