React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Tag} = require '../../../shared/aris.js'

exports.SearchBox = React.createClass
  displayName: 'SearchBox'

  propTypes:
    tags:          T.arrayOf T.instanceOf Tag
    checkedTags:   T.arrayOf T.instanceOf Tag
    onSearch:      T.func
    searchText:    T.string
    notesMinDate:  T.instanceOf Date
    notesMaxDate:  T.instanceOf Date
    searchMinDate: T.instanceOf Date
    searchMaxDate: T.instanceOf Date

  handleChange: ->
    tags =
      tag for tag in @props.tags when @refs["searchTag#{tag.tag_id}"].checked
    text = @refs.searchText.value
    searchMinDate = new Date(parseInt @refs.searchMinDate.value)
    searchMaxDate = new Date(parseInt @refs.searchMaxDate.value)
    searchMinDate = null if @props.notesMinDate.getTime() is searchMinDate.getTime()
    searchMaxDate = null if @props.notesMaxDate.getTime() is searchMaxDate.getTime()
    @props.onSearch tags, text, searchMinDate, searchMaxDate

  render: ->
    <form>
      { for tag in @props.tags
          <p key={tag.tag_id}>
            <label>
              <input type="checkbox"
                ref="searchTag#{tag.tag_id}"
                checked={tag in @props.checkedTags}
                onChange={@handleChange}
              />
              { tag.tag }
            </label>
          </p>
      }
      <p>
        <input type="text" ref="searchText" value={@props.searchText} onChange={@handleChange} />
      </p>
      <p>
        { """
          #{(@props.searchMinDate ? @props.notesMinDate)?.toLocaleString()}
          to
          #{(@props.searchMaxDate ? @props.notesMaxDate)?.toLocaleString()}
          """
        }
      </p>
      <p>
        <input type="range" ref="searchMinDate"
          min={@props.notesMinDate?.getTime()}
          max={@props.notesMaxDate?.getTime()}
          step={1}
          value={(@props.searchMinDate ? @props.notesMinDate)?.getTime()}
          onChange={@handleChange}
          style={width: '500px'} />
      </p>
      <p>
        <input type="range" ref="searchMaxDate"
          min={@props.notesMinDate?.getTime()}
          max={@props.notesMaxDate?.getTime()}
          step={1}
          value={(@props.searchMaxDate ? @props.notesMaxDate)?.getTime()}
          onChange={@handleChange}
          style={width: '500px'} />
      </p>
    </form>
