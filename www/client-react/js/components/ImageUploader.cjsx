React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes

exports.ImageUploader = React.createClass
  displayName: 'ImageUploader'

  propTypes:
    url:           T.string
    onImageSelect: T.func
    width:         T.string
    height:        T.string

  selectImage: ->
    input = document.createElement 'input'
    input.type = 'file'
    input.onchange = (e) =>
      file = e.target.files[0]
      fr = new FileReader
      fr.onload = =>
        @props.onImageSelect fr.result
      fr.readAsDataURL file
    input.click()

  render: ->
    <div style={
      backgroundImage: if @props.url? then "url(#{@props.url})" else ''
      backgroundSize: 'contain'
      backgroundRepeat: 'no-repeat'
      backgroundPosition: 'center'
      width: @props.width
      height: @props.height
      border: '1px solid black'
    } onClick={@selectImage} />
