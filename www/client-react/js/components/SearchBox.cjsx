React = require 'react'
ReactDOM = require 'react-dom'
update = require 'react-addons-update'
T = React.PropTypes
{Tag} = require '../../../shared/aris.js'

exports.SearchBox = React.createClass
  displayName: 'SearchBox'

  propTypes:
    tags:        T.arrayOf T.instanceOf Tag
    checkedTags: T.arrayOf T.instanceOf Tag
    onSearch:    T.func
    searchText:  T.string

  handleChange: ->
    tags =
      tag for tag in @props.tags when @refs["searchTag#{tag.tag_id}"].getDOMNode().checked
    text = @refs.searchText.getDOMNode().value
    @props.onSearch tags, text

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
    </form>
