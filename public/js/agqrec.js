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

    $('#createScheduleDialog').dialog({
        autoOpen: false,
        closeOnEscape: false,
        draggable: false,
        modal: true,
        width: 700
    });
});
