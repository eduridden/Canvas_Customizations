////////////////////////////////////////////////////
// START SANDBOX                                   //
////////////////////////////////////////////////////

/**
// @name        Canvas LMS - Create a Sandbox Button
// @namespace   https://github.com/eduridden/Canvas_Customizations
// @author      Aaron Leonard <leonaa@nv.ccsd.net> [v1]
// @author      Robert Carroll <carror@nv.ccsd.net> [v1.0.1]
// @author      Julian Ridden <julian@quizizz.com> [v2]
**/

// Define a global object called `JR` so as not to pollute the global scope
var JR = {
    // Create a nested object to hold utility
    util: {}
}

JR.util.onPage = function(rex, fn, fnfail) {
    'use strict';

    var match = location.pathname.match(rex);

    if (typeof fn !== 'undefined' && match) {
        return fn();
    }
    if (typeof fnfail !== 'undefined' && !match) {
        return fnfail();
    }
    return match ? match : false;
}

JR.util.hasAnyRole = function() {
    'use strict';

    var roles = Array.from(arguments);
    // Prevent errors if `ENV.current_user_roles` is not defined
    if (!ENV || !Array.isArray(ENV.current_user_roles)) {
        return false;
    }
    return roles.some(role => ENV.current_user_roles.includes(role));
};


(function() {
    var handleNewCourse = function() {
        if (JR.util.hasAnyRole("admin")) {
            // Show the element if the user has the "admin" role
            document.getElementById('start_new_course').style.display = 'block';
        } else {
            // Otherwise, remove it
            var element = document.getElementById('start_new_course');
            if (element) {
                element.parentNode.removeChild(element);
            }
        }
    };

    // Immediately invoke the function to execute the behavior
    handleNewCourse();
})();

(function() {
    var sandbox = {
        cfg: {
            sandbox_acct_id: 104,
            term_id: 102,
            roles: ['teacher']
        }
    }

    sandbox.alert = function(title, message) {
        var alertElement = document.getElementById('enrollAlert');
        alertElement.innerHTML = message;
        // Assuming you have some custom dialog function for this:
        alertElement.title = title;
        // Display logic for your custom dialog should go here
    }

    sandbox.codedDate = function(date) {
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: '2-digit',
            year: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        })
        .replace(/\,\s/g, '_')
        .replace(/\s/g, '')
        .toUpperCase()
        .replace(/AM|PM/, '');
    }

    sandbox.getSISID = function() {
        return fetch('/api/v1/courses?per_page=1&enrollment_type=teacher&enrollment_state=active')
            .then(response => response.json())
            .then(courses => {
                if (courses.length === 0) return Promise.reject();
                return fetch(`/api/v1/courses/${courses[0].id}/enrollments?user_id=self`)
                    .then(response => response.json());
            })
            .then(enroll => {
                if (enroll.length === 0 || !enroll[0].user.sis_user_id) return Promise.reject();
                return enroll[0].user.sis_user_id;
            });
    }

    sandbox.enroll = function(employee_id, shortName) {
        var DATE_FM = sandbox.codedDate(new Date()),
            long_name = `Sandbox - ${ENV.current_user.display_name} -- ${DATE_FM}`,
            short_name = `SB-${shortName}`;

        var data = {
            course: {
                name: long_name,
                course_code: short_name,
                is_public: false,
                is_public_to_auth_users: false,
                enrollment_term_id: sandbox.cfg.term_id
            },
            enroll_me: true
        };

        return fetch(`/api/v1/accounts/${sandbox.cfg.sandbox_acct_id}/courses`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        }).then(response => response.json())
          .then(res => window.location = `/courses/${res.id}`)
          .catch(() => sandbox.alert('Error', 'There was an error creating the sandbox.'));
    }

    sandbox.init = function() {
        var enrollBtn = document.createElement('button');
        enrollBtn.classList.add('btn', 'button-sidebar-wide', 'pull-right');
        enrollBtn.id = 'enrollsandboxBtn';
        enrollBtn.style.marginTop = '10px';
        enrollBtn.innerText = 'Create a sandbox';

        // Assuming '.header-bar' is a class name for a specific element:
        document.querySelector('.header-bar').prepend(enrollBtn);

        var enrollHtml = `
            <div id="enrollsandbox" style="display: none;">
                <table class="formtable">
                    <tr class="formrow">
                        <td><label>Employee Id:<span>*</span></label></td>
                        <td><input type="text" name="employee_id" /></td>
                    </tr>
                    <tr class="formrow">
                        <td><label>Enter Course Short Name:<span>*</span></label></td>
                        <td><input type="text" name="short_name" required maxlength="16" /></td>
                    </tr>
                </table>
            </div>
            <div id="enrollAlert"></div>`;
        document.body.insertAdjacentHTML('beforeend', enrollHtml);

        enrollBtn.addEventListener('click', function(e) {
            e.preventDefault();
            enrollBtn.disabled = true;
            enrollBtn.innerText = 'Working...';
            enrollBtn.classList.add('btn-primary');

            sandbox.getSISID()
                .then(sis_user_id => {
                    // Handle the enrollment dialog logic here
                })
                .then(data => sandbox.enroll(data.employee_id, data.shortName))
                .then(() => {
                    enrollBtn.innerText = 'Done!';
                    enrollBtn.classList.add('btn-success');
                })
                .catch(() => {
                    enrollBtn.innerText = 'Create a sandbox';
                    enrollBtn.disabled = false;
                    enrollBtn.classList.remove('btn-success', 'btn-primary');
                });
        });
    }

    JR.util.onPage(/\/courses$/, function() {
        if (JR.util.hasAnyRole.apply(this, sandbox.cfg.roles)) {
            sandbox.init();
        }
    });
})();
