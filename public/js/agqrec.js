ScheduleData = [];

function showScheduleTable (schedules) {
    ScheduleData = schedules;
    $('#schedule_table tbody tr').remove();
    $.each(schedules, function(idx, schedule) {
        var style = (idx%2 == 1) ? "pure-table-odd" : "";
        $('#schedule_table tbody').append(
            $('<tr></tr>').addClass(style)
                .append($("<td></td>").text(schedule.provider))
                .append($("<td></td>").text(schedule.title))
                .append($("<td></td>").text(schedule.at))
                .append($('<td></td>')
                        .append($('<span onclick="editScheduleTableRow(this);" class="table-edit glyphicon glyphicon-pencil"></span>'))
                        .append($('<span onclick="removeScheduleTableRow(this);" class="glyphicon glyphicon-trash"></span>')))
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
}

function reloadScheduleTable (schedules) {
    if (!schedules) {
        $.getJSON("/api/schedules", function(schedules) {
            showScheduleTable(schedules);
        });
    } else {
        showScheduleTable(schedules);
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

        reloadScheduleTable();
    });
}

function reloadClockwork() {
    updateSchedules();
    $.get('/api/reload_clockwork');
}

$(document).ready(function() {
    reloadScheduleTable();
});
