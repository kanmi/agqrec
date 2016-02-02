function ScheduleTable(target, endpoint) {
    this.target = target;
    this.endpoint = endpoint;
    this.editItems = [];
    this.scheduleData = [];
}
ScheduleTable.prototype = {
    show : function(schedules) {
        var caller = this;

        caller.scheduleData = schedules;
        $(caller.target + ' tr').remove();

        $.each(schedules, function(idx, schedule) {
            var editItemsColumn = $('<td></td>');
            $.each(caller.editItems, function(_, item) { editItemsColumn.append($(item)); });
            $(caller.target).append(
                $('<tr></tr>')
                    .append($("<td></td>").text(schedule.provider))
                    .append($("<td></td>").text(schedule.title))
                    .append($("<td></td>").text(schedule.at))
                    .append(editItemsColumn)
            );
        });
    },

    reload : function (schedules) {
        var caller = this;

        if (!schedules) {
            $.getJSON(caller.endpoint, function(schedules) {
                caller.show(schedules);
            });
        }

        caller.show(schedules);
    },

    getScheduleTitles : function() {
        return $(this.target + ' tr').map(function() {
            return $($(this).children()[1]).text();
        })
    },

    remove : function (obj) {
        var caller = this;

        var target = $(obj).closest('tr');
        var title = $(target.children()[1]).text();
        caller.scheduleData = caller.scheduleData.filter(function(v, i) {
            return (v.title !== title);
        });
        target.remove();

        $('#menu-save').removeClass('glyphicon-floppy-saved');
        $('#menu-save').addClass('glyphicon-floppy-disk');
    }

};

function reloadClockwork() {
    $.get('/api/reload_clockwork');
}

function showScheduleDialog() {
    $('#createScheduleDialog').dialog('open');
}

$(document).ready(function() {
    scheduleTable = new ScheduleTable('#schedule_table tbody', '/api/schedules');
    scheduleTable.editItems.push('<span onclick="scheduleTable.deleteSchedule(this);" class="glyphicon glyphicon-trash"></span>');
    scheduleTable.deleteSchedule = function (obj) {
        var caller = this;
        var target = caller.scheduleData.splice($('#schedule_table tbody tr').index($(obj).closest('tr')), 1)[0];
        caller.remove(obj);
        availableTable
        $.ajax({
            url: '/api/schedules/' + target.title,
            type: 'DELETE'
        });
    };
    
    availableTable = new ScheduleTable('#available_schedule_table tbody', '/api/available_schedules');
    availableTable.editItems.push('<span onclick="availableTable.addSchedule(this);" class="glyphicon glyphicon-plus"></span>');
    availableTable.addSchedule = function (obj) {
        var target_at = $($(obj).closest('tr').children()[2]).text();
        var new_schedule = this.scheduleData.find(function (schedule) { return schedule.at == target_at; });
        this.remove(obj);
        scheduleTable.scheduleData.push(new_schedule);
        scheduleTable.reload(scheduleTable.scheduleData);

        $.ajax({
            type: "POST",
            url: "/api/schedules",
            data: JSON.stringify(new_schedule),
            dataType: "json",
            contentType : "application/json",
            success: function(){}
        });
    };

    scheduleTable.reload();
    availableTable.reload();
    
    $('#createScheduleDialog').dialog({
        autoOpen: false,
        closeOnEscape: false,
        draggable: false,
        modal: true,
        width: 700
    });
});
