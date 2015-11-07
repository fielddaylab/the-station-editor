React = require 'react/addons'
T = React.PropTypes
{Tag} = require '../../../shared/aris.js'
{ImageUploader} = require './ImageUploader.js'

exports.Uploader = React.createClass
  propTypes:
    description:   T.string
    tags:          T.arrayOf T.instanceOf Tag
    tag:           T.instanceOf Tag
    url:           T.string
    latitude:      T.number
    longitude:     T.number
    onChange:      T.func

  handleChange: (url = @props.url) ->
    @onChange
      description: @refs.description.value
      url: url

  render: ->
    <div>
      <input ref="description" type="text" value={@props.description} onChange={=> @handleChange()} />
      <ImageUploader
        url={@props.url}
        onImageSelect={@handleChange}
        width="100px"
        height="100px"
      />
    </div>
