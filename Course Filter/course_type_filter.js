////////////////////////////////////////////////////
// START COURSE FILTER CODE                       //
////////////////////////////////////////////////////

$(document).ready(function() {
  if ($("div.context_module").length > 0) {

    $("div.header-bar").append("<div><ul id='module_filters' style='list-style-type: none; display: inline;'></ul></div>");

    var item_types = [{id: "wiki_page", label: "Pages", icon: "icon-document"},
                      {id: "assignment", label: "Assignments", icon: "icon-assignment"},
                      {id: "quiz", label: "Quizzes", icon: "icon-quiz"},
                      {id: "lti-quiz", label: "Quizzes", icon: "icon-quiz icon-Solid"},
                      {id: "discussion_topic", label: "Discussion Topics", icon: "icon-discussion"},
                      {id: "external_url", label: "Links", icon: "icon-link"},
                      {id: "attachment", label: "Files", icon: "icon-paperclip"},
                      {id: "context_external_tool", label: "External Tools", icon: "icon-integrations"}];

    item_types.forEach(function(type) {
      var icon = `<i id="module_filter_${type['id']}" class="${type['icon']}" title="${type['label']}"></i>`;

      $("ul#module_filters").append(`<li style="padding: 0 1em 0 0; display: inline-block;"><input type="checkbox" id="${type['id']}" name="${type['id']}" checked style="display: none;"> <label for="${type['id']}">${icon}</label></li>`);

      $(`#${type['id']}`).change(function() {
        if (this.checked == true) {
          $(`li.${type['id']}`).show();
          $(`#module_filter_${type['id']}`).css('background-color', '');
        }
        else {
          $(`li.${type['id']}`).hide();
          $(`#module_filter_${type['id']}`).css('background-color', 'darkgrey');
        }
      });
    });
  }
});