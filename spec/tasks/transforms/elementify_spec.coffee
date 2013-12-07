# This spec depends on a fixture elements...
# `spec/tasks/transforms/fixtures/app/elements/test-element.*`
# `spec/tasks/transforms/fixtures/app/elements/test-element-no-template.*`
describe 'tasks/transforms/elementify', ->
  beforeEach angular.mock.module "zeitgeist"
  beforeEach inject ($compile, $rootScope)->
    @elementWithNoTemplate = $compile(
      "<test-element-no-template></test-element-no-template>"
    )($rootScope)
    @element = $compile(
      "<test-element></test-element>"
    )($rootScope)
    $rootScope.$digest()

    # Chrome/IE/Safari: Styles are not applied to non-DOM elements
    document.body.appendChild @element[0]
    document.body.appendChild @elementWithNoTemplate[0]

  afterEach ->
    @elementWithNoTemplate.remove()
    @element.remove()

  it """
     Generates an angular directive with a proper name, inlined template,
     and restricted to elements.
     """, ->
    expect(@element.text().trim()).toEqual "test-element content"

  it "Uses an empty template when there is no template", ->
    expect(@elementWithNoTemplate.text()).toEqual ""

  it "Links CSS", ->
    waitsFor -> window.getComputedStyle(@element[0]).color is "rgb(255, 0, 0)"
    waitsFor -> window.getComputedStyle(@elementWithNoTemplate[0]).color is "rgb(0, 0, 255)"
