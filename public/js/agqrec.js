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
                    .hover(function () { $(this).addClass('highlight-td'); },
                           function () { $(this).removeClass('highlight-td'); })
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

scheduled_jobs = [];
$(document).ready(function() {
    $.getJSON('/api/schedules', function (schedules) {
        scheduled_jobs = schedules;
    });

    $.getJSON('/api/available_schedules?all', function (schedules) {
        var wd = [ 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun' ];
        var schedules_by_wd = {}, wd_count = [], time_table = [];
        $.each(wd, function () {
            schedules_by_wd[this] = [];
            wd_count[this] = 0;
        });
        $.each(schedules, function () {
            schedules_by_wd[this.at.split(' ')[0].toLowerCase()].push(this);
        });
        $.each(schedules_by_wd, function (key) {
            schedules_by_wd[key].sort(function (a, b) {
                if(a.at < b.at) return -1;
                if(a.at > b.at) return 1;
                return 0;
            });
        });

        while(wd.find( function(v) { return schedules_by_wd[v].length != 0 } ) ) {
            var row = [];
            $.each(schedules_by_wd, function (key) {
                if (wd_count[key] == 0 && schedules_by_wd[key].length != 0) {
                    var schedule = schedules_by_wd[key].shift();
                    wd_count[key] += schedule.length / 30;
                    row.push(schedule);
                }
                wd_count[key] -= 1;
            });
            time_table.push(row);
        }

        $.each(time_table, function(idx, schedules) {
            var rowspan = 1;
            for(; time_table[idx+rowspan] && time_table[idx+rowspan].length == 0; rowspan++);
            
            var row = $('<tr></tr>').append($('<td></td>')
                                            .text(schedules.length != 0 ? schedules[0].at.split(' ')[1] : '')
                                            .attr("rowspan", rowspan));

            $.each(schedules, function(_, schedule) {
                var td = $('<td></td>')
                    .text(this.title)
                    .attr("rowspan", this.length/30)
                    .attr("schedule", JSON.stringify(this));
                var is_scheduled = scheduled_jobs.find( function (v) {
                                        return ( v.provider == schedule.provider &&
                                                 v.title    == schedule.title    &&
                                                 v.at       == schedule.at ); });
                                
                var tdClass = is_scheduled ? 'scheduled-td' : '';
                if (this.title == '放送休止') {
                    tdClass = 'schedule-disable';
                } else {
                    td.hover( function () { $(this).addClass('highlight-td'); },
                              function () { $(this).removeClass('highlight-td'); });

                    td.click( function () {
                        var td = this;
                        var schedule_json = td.getAttribute('schedule');
                        var schedule = JSON.parse(schedule_json);
                        var isScheduled = scheduled_jobs.find( function (v) {
                                        return ( v.provider == schedule.provider &&
                                                 v.title    == schedule.title    &&
                                                 v.at       == schedule.at ); });

                        if (isScheduled) {
                            $.ajax({
                                url: '/api/schedules',
                                type: 'DELETE',
                                data: schedule_json,
                                dataType: "json",
                                contentType : "application/json",
                                success: function() {
                                    $(td).removeClass('scheduled-td');
                                    scheduled_jobs = scheduled_jobs.filter( function (v) {
                                        return ( v.provider == schedule.provider &&
                                                 v.title    == schedule.title    &&
                                                 v.at       == schedule.at );
                                    });
                                }
                            });
                        } else {
                            $.ajax({
                                type: "POST",
                                url: "/api/schedules",
                                data: schedule_json,
                                dataType: "json",
                                contentType : "application/json",
                                success: function(){
                                    $(td).addClass('scheduled-td');
                                    scheduled_jobs.push(schedule);
                                }
                            });
                        }
                    });
                }

                td.addClass(tdClass);
                row.append(td);
            });
            $('#time_table tbody').append(row);
        });
    });
    
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
    
    $('#createScheduleDialog').dialog({
        autoOpen: false,
        closeOnEscape: false,
        draggable: false,
        modal: true,
        width: 700
    });
});
