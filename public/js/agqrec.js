ScheduleData = [];
AvailableScheduleData = [];

function showScheduleTable (schedules, target) {
    var editItems = [];
    if(!target || target == '#schedule_table tbody') {
        target = '#schedule_table tbody';
        editItems.push('<span onclick="editScheduleTableRow(this);" class="table-edit glyphicon glyphicon-pencil"></span>');
        editItems.push('<span onclick="removeScheduleTableRow(this);" class="glyphicon glyphicon-trash"></span>');
    } else {
        editItems.push('<span onclick="addScheduleTableRow(this);" class="glyphicon glyphicon-plus"></span>');
    }

    ScheduleData = schedules;
    $(target + ' tr').remove();
    $.each(schedules, function(idx, schedule) {
        var style = (idx%2 == 1) ? "pure-table-odd" : "";
        var editItemsColumn = $('<td></td>');
        $.each(editItems, function(_, item) { editItemsColumn.append($(item)); });

        $(target).append(
            $('<tr></tr>').addClass(style)
                .append($("<td></td>").text(schedule.provider))
                .append($("<td></td>").text(schedule.title))
                .append($("<td></td>").text(schedule.at))
                .append(editItemsColumn)
        );
    });
}

function removeScheduleTableRow (obj) {
    var target = $(obj).closest('tr');
    var title = $(target.children()[1]).text();
    ScheduleData = ScheduleData.filter(function(v, i) {
        return (v.title !== title);
    });
    target.remove();

    $('#menu-save').removeClass('glyphicon-floppy-saved');
    $('#menu-save').addClass('glyphicon-floppy-disk');
}

function reloadScheduleTable (schedules, target, endpoint) {
    target = target || '#schedule_table tbody';
    endpoint = endpoint || '/api/schedules';

    if (!schedules) {
        $.getJSON(endpoint, function(schedules) {
            showScheduleTable(schedules, target);
        });
    } else {
        showScheduleTable(schedules, target);
    }
}

function getScheduleTitles () {
    return $('#schedule_table tbody tr').map(function() {
        return $($(this).children()[1]).text();
    });
}

function updateSchedules() {
    $.getJSON("/api/schedules", function(schedules) {
        var removedTitles = schedules.map(function(schedule) {
            return schedule.title;
        }).filter(function(title) {
            return $.inArray(title, getScheduleTitles()) < 0;
        });

        // delete removed schedules
        $.each(removedTitles, function(idx, title) {
            $.ajax({
                url: '/api/schedules/' + title,
                type: 'DELETE'
            });

        });

        $('#menu-save').removeClass('glyphicon-floppy-disk');
        $('#menu-save').addClass('glyphicon-floppy-saved');

        reloadScheduleTable();
    });
}

function reloadClockwork() {
    updateSchedules();
    $.get('/api/reload_clockwork');
}

function showScheduleDialog() {
    $('#createScheduleDialog').dialog('open');
}

function createSchedule(forms) {
    var data = {};
    $.each(forms, function(idx, form) {
        data[form.id] = form.value;
    });

    $.ajax({
        type: "POST",
        url: "/api/schedules",
        data: JSON.stringify(data),
        dataType: "json",
        contentType : "application/json",
        success: function(){}
    });

    reloadScheduleTable();
}

$(document).ready(function() {
    reloadScheduleTable();
    reloadScheduleTable(undefined, '#available_schedule_table tbody', '/api/available_schedules');
    $('#createScheduleDialog').dialog({
        autoOpen: false,
        closeOnEscape: false,
        draggable: false,
        modal: true,
        width: 700
    });
});
