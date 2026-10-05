/**
 * Smart Campus Placement - Apps Script Code.gs Additions (Phases 6, 7 & 8)
 * 
 * INSTRUCTIONS FOR GOOGLE APPS SCRIPT:
 * 1. Open your existing Google Spreadsheet.
 * 2. Go to Extensions > Apps Script to open Code.gs.
 * 3. In doGet(e), add action handling for Phase 8, Company Module & Phase 13 Recruiter Feedback:
 * 
 *    if (action === 'get_notifications') {
 *      return getNotifications(e);
 *    } else if (action === 'mark_notification_read') {
 *      return markNotificationRead(e);
 *    } else if (action === 'post_job') {
 *      return handlePostJob(ss, e.parameter);
 *    } else if (action === 'get_company_applications') {
 *      return handleGetCompanyApplications(ss, e.parameter);
 *    } else if (action === 'update_application_status') {
 *      return handleUpdateApplicationStatus(ss, e.parameter);
 *    } else if (action === 'submit_recruiter_feedback') {
 *      return handleSubmitRecruiterFeedback(ss, e.parameter);
 *    } else if (action === 'get_recruiter_feedback') {
 *      return handleGetRecruiterFeedback(ss, e.parameter);
 *    } else if (action === 'get_admin_statistics') {
 *      return handleGetAdminStatistics(ss, e.parameter);
 *    } else if (action === 'get_admin_students') {
 *      return handleGetAdminStudents(ss, e.parameter);
 *    } else if (action === 'get_admin_companies') {
 *      return handleGetAdminCompanies(ss, e.parameter);
 *    } else if (action === 'get_most_demanded_skills') {
 *      return handleGetMostDemandedSkills(ss, e.parameter);
 *    } else if (action === 'get_readiness_distribution') {
 *      return handleGetReadinessDistribution(ss, e.parameter);
 *    } else if (action === 'get_top_recommended_jobs') {
 *      return handleGetTopRecommendedJobs(ss, e.parameter);
 *    } else if (action === 'get_placement_trends') {
 *      return handleGetPlacementTrends(ss, e.parameter);
 *    } else if (action === 'send_broadcast' || action === 'send_system_broadcast') {
 *      return handleSendBroadcast(ss, e.parameter);
 *    } else if (action === 'get_broadcasts' || action === 'get_system_broadcasts') {
 *      return handleGetBroadcasts(ss, e.parameter);
 *    } else if (action === 'delete_student') {
 *      return handleDeleteStudent(ss, e.parameter);
 *    } else if (action === 'update_student') {
 *      return handleUpdateStudent(ss, e.parameter);
 *    }
 * 
 * 4. Inside your existing applyForJob(e) function, after appending the new application row,
 *    call addNotification to auto-create a notification:
 *    addNotification(ss, userId, "Application Submitted", "Your application for Job ID " + jobId + " was successfully submitted.", "application");
 * 
 * 5. Paste the helper functions below at the bottom of Code.gs:
 * 6. Click Deploy > Manage Deployments > Edit (pencil icon) > Version: New version > Deploy.
 */

// Phase 6 Functions
function handleGetJobs(ss, params) {
  try {
    var sheet = ss.getSheetByName("Jobs");
    if (!sheet) {
      return jsonResponse({ success: true, jobs: [] });
    }
    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: true, jobs: [] });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var jobs = [];
    for (var i = 1; i < data.length; i++) {
      var row = data[i];

      var getVal = function (names) {
        for (var k = 0; k < names.length; k++) {
          var idx = headers.indexOf(names[k].toLowerCase());
          if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
            return row[idx].toString().trim();
          }
        }
        return "";
      };

      var jobId = getVal(["jobid", "id"]);
      var title = getVal(["title", "jobtitle"]);
      var company = getVal(["company", "companyname"]);
      var location = getVal(["location"]);
      var jobType = getVal(["jobtype", "type"]);
      var skills = getVal(["skills", "requiredskills", "skillsrequired"]);
      var salary = getVal(["salary", "stipend"]);
      var description = getVal(["description", "jobdescription"]);
      var status = getVal(["status", "jobstatus"]);
      var postedDate = getVal(["posteddate", "date", "createdat"]);

      var statusLower = status.toLowerCase();
      if (statusLower && statusLower !== "active") {
        continue;
      }

      if (jobId || title) {
        jobs.push({
          jobId: jobId || ("JOB" + i),
          title: title,
          company: company,
          location: location,
          jobType: jobType,
          skills: skills,
          salary: salary,
          description: description,
          status: status || "Active",
          postedDate: postedDate
        });
      }
    }

    return jsonResponse({ success: true, jobs: jobs });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error fetching jobs: " + err.toString() });
  }
}

function handleGetJobDetails(ss, params) {
  try {
    var jobIdReq = (params.jobId || params.id || "").toString().trim();
    if (!jobIdReq) {
      return jsonResponse({ success: false, message: "jobId parameter is required" });
    }

    var sheet = ss.getSheetByName("Jobs");
    if (!sheet) {
      return jsonResponse({ success: false, message: "Job not found" });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: false, message: "Job not found" });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    for (var i = 1; i < data.length; i++) {
      var row = data[i];

      var getVal = function (names) {
        for (var k = 0; k < names.length; k++) {
          var idx = headers.indexOf(names[k].toLowerCase());
          if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
            return row[idx].toString().trim();
          }
        }
        return "";
      };

      var jobId = getVal(["jobid", "id"]);
      if (jobId.toLowerCase() === jobIdReq.toLowerCase()) {
        var status = getVal(["status", "jobstatus"]);
        var statusLower = status.toLowerCase();
        if (statusLower && statusLower !== "active") {
          return jsonResponse({ success: false, message: "Job not found" });
        }

        var jobObj = {
          jobId: jobId,
          title: getVal(["title", "jobtitle"]),
          company: getVal(["company", "companyname"]),
          location: getVal(["location"]),
          jobType: getVal(["jobtype", "type"]),
          skills: getVal(["skills", "requiredskills", "skillsrequired"]),
          salary: getVal(["salary", "stipend"]),
          description: getVal(["description", "jobdescription"]),
          status: status || "Active",
          postedDate: getVal(["posteddate", "date", "createdat"])
        };

        return jsonResponse({ success: true, job: jobObj });
      }
    }

    return jsonResponse({ success: false, message: "Job not found" });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error fetching job details: " + err.toString() });
  }
}

// Phase 7 Functions
function applyForJob(e) {
  try {
    var ss;
    var params;

    if (e && typeof e.getSheetByName === "function") {
      ss = e;
      params = arguments[1] || {};
    } else {
      ss = (typeof SpreadsheetApp !== "undefined") ? SpreadsheetApp.getActiveSpreadsheet() : null;
      params = (e && e.parameter) ? e.parameter : (e || {});
    }

    var userId = (params.userId || params.userid || "").toString().trim();
    var jobId = (params.jobId || params.jobid || "").toString().trim();

    if (!userId || !jobId) {
      return jsonResponse({ success: false, message: "User ID and Job ID are required" });
    }

    if (!ss) {
      return jsonResponse({ success: false, message: "Spreadsheet context missing" });
    }

    var sheet = ss.getSheetByName("Applications");
    if (!sheet) {
      sheet = ss.insertSheet("Applications");
      sheet.appendRow(["Application ID", "Job ID", "User ID", "Applied Date", "Status"]);
    }

    var data = sheet.getDataRange().getValues();
    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var jobIdCol = headers.indexOf("job id");
    if (jobIdCol === -1) jobIdCol = headers.indexOf("jobid");
    if (jobIdCol === -1) jobIdCol = 1;

    var userIdCol = headers.indexOf("user id");
    if (userIdCol === -1) userIdCol = headers.indexOf("userid");
    if (userIdCol === -1) userIdCol = 2;

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var rJobId = row[jobIdCol] ? row[jobIdCol].toString().trim().toLowerCase() : "";
      var rUserId = row[userIdCol] ? row[userIdCol].toString().trim().toLowerCase() : "";

      if (rJobId === jobId.toLowerCase() && rUserId === userId.toLowerCase()) {
        return jsonResponse({ success: false, message: "You have already applied for this job" });
      }
    }

    var appId = "APP" + new Date().getTime();
    var appliedDate = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm");
    var status = "Applied";

    sheet.appendRow([appId, jobId, userId, appliedDate, status]);

    // Phase 8: Auto-create Notification on Successful Job Application
    addNotification(ss, userId, "Application Submitted", "Your application for Job ID " + jobId + " was successfully submitted.", "application");

    return jsonResponse({
      success: true,
      message: "Application submitted successfully",
      applicationId: appId
    });
  } catch (err) {
    return jsonResponse({ success: false, message: "Failed to submit application: " + err.toString() });
  }
}

function handleApplyJob(ss, params) {
  return applyForJob(ss, params);
}

function getMyApplications(e) {
  try {
    var ss;
    var params;

    if (e && typeof e.getSheetByName === "function") {
      ss = e;
      params = arguments[1] || {};
    } else {
      ss = (typeof SpreadsheetApp !== "undefined") ? SpreadsheetApp.getActiveSpreadsheet() : null;
      params = (e && e.parameter) ? e.parameter : (e || {});
    }

    var userId = (params.userId || params.userid || "").toString().trim();
    if (!userId) {
      return jsonResponse({ success: false, message: "User ID is required" });
    }

    if (!ss) {
      return jsonResponse({ success: false, message: "Spreadsheet context missing" });
    }

    var appSheet = ss.getSheetByName("Applications");
    if (!appSheet) {
      return jsonResponse({ success: true, applications: [] });
    }

    var appData = appSheet.getDataRange().getValues();
    if (appData.length <= 1) {
      return jsonResponse({ success: true, applications: [] });
    }

    var appHeaders = appData[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var getAppVal = function (row, names) {
      for (var k = 0; k < names.length; k++) {
        var idx = appHeaders.indexOf(names[k].toLowerCase());
        if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
          return row[idx].toString().trim();
        }
      }
      return "";
    };

    var jobsMap = {};
    var jobsSheet = ss.getSheetByName("Jobs");
    if (jobsSheet) {
      var jobsData = jobsSheet.getDataRange().getValues();
      if (jobsData.length > 1) {
        var jobHeaders = jobsData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getJobVal = function (jRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = jobHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && jRow[idx] !== undefined && jRow[idx] !== null) {
              return jRow[idx].toString().trim();
            }
          }
          return "";
        };

        for (var j = 1; j < jobsData.length; j++) {
          var jRow = jobsData[j];
          var jId = getJobVal(jRow, ["jobid", "id", "job id"]);
          if (jId) {
            jobsMap[jId.toLowerCase()] = {
              title: getJobVal(jRow, ["title", "jobtitle", "job title"]),
              company: getJobVal(jRow, ["company", "companyname", "company name"]),
              location: getJobVal(jRow, ["location", "joblocation", "job location"]),
              jobType: getJobVal(jRow, ["jobtype", "type", "job type"]),
              salary: getJobVal(jRow, ["salary", "stipend", "pay", "ctc"])
            };
          }
        }
      }
    }

    var applications = [];
    for (var i = 1; i < appData.length; i++) {
      var row = appData[i];
      var rUserId = getAppVal(row, ["user id", "userid"]);
      if (rUserId && rUserId.toLowerCase() === userId.toLowerCase()) {
        var appId = getAppVal(row, ["application id", "applicationid", "appid", "id"]);
        var jobId = getAppVal(row, ["job id", "jobid"]);
        var appliedDate = getAppVal(row, ["applied date", "applieddate", "date"]);
        var status = getAppVal(row, ["status", "applicationstatus"]);

        var jobDetails = jobId ? jobsMap[jobId.toLowerCase()] : null;

        applications.push({
          applicationId: appId || ("APP" + i),
          jobId: jobId,
          userId: rUserId,
          appliedDate: appliedDate,
          status: status || "Applied",
          title: jobDetails ? (jobDetails.title || "") : "",
          company: jobDetails ? (jobDetails.company || "") : "",
          location: jobDetails ? (jobDetails.location || "") : "",
          jobType: jobDetails ? (jobDetails.jobType || "") : "",
          salary: jobDetails ? (jobDetails.salary || "") : ""
        });
      }
    }

    return jsonResponse({ success: true, applications: applications });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error loading applications: " + err.toString() });
  }
}

function handleGetMyApplications(ss, params) {
  return getMyApplications(ss, params);
}

// Phase 8 Functions: Notifications
function addNotification(ss, userId, title, message, type) {
  try {
    var notifSheet = ss.getSheetByName("Notifications");
    if (!notifSheet) {
      notifSheet = ss.insertSheet("Notifications");
      notifSheet.appendRow(["Notification ID", "User ID", "Title", "Message", "Type", "Date", "Status"]);
    }
    var notifId = "NOTIF" + new Date().getTime();
    var dateStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm");
    notifSheet.appendRow([notifId, userId, title, message, type || "general", dateStr, "unread"]);
    return true;
  } catch (err) {
    return false;
  }
}

function getNotifications(e) {
  try {
    var ss;
    var params;

    if (e && typeof e.getSheetByName === "function") {
      ss = e;
      params = arguments[1] || {};
    } else {
      ss = (typeof SpreadsheetApp !== "undefined") ? SpreadsheetApp.getActiveSpreadsheet() : null;
      params = (e && e.parameter) ? e.parameter : (e || {});
    }

    var userId = (params.userId || params.userid || "").toString().trim();
    if (!userId) {
      return jsonResponse({ success: false, message: "User ID is required" });
    }

    if (!ss) {
      return jsonResponse({ success: false, message: "Spreadsheet context missing" });
    }

    var sheet = ss.getSheetByName("Notifications");
    if (!sheet) {
      return jsonResponse({ success: true, notifications: [], unreadCount: 0 });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: true, notifications: [], unreadCount: 0 });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var getVal = function (row, names) {
      for (var k = 0; k < names.length; k++) {
        var idx = headers.indexOf(names[k].toLowerCase());
        if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
          return row[idx].toString().trim();
        }
      }
      return "";
    };

    var notifications = [];
    var unreadCount = 0;

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var rUserId = getVal(row, ["user id", "userid"]);
      var isTargetUser = (rUserId.toLowerCase() === userId.toLowerCase()) || (rUserId.toLowerCase() === "all");

      if (isTargetUser) {
        var notifId = getVal(row, ["notification id", "notificationid", "id"]);
        var title = getVal(row, ["title"]);
        var message = getVal(row, ["message"]);
        var type = getVal(row, ["type"]);
        var dateStr = getVal(row, ["date", "createdat"]);
        var status = getVal(row, ["status", "isread"]);

        var isReadBool = (status.toLowerCase() === "read" || status.toLowerCase() === "true");

        if (!isReadBool) {
          unreadCount++;
        }

        notifications.push({
          notificationId: notifId || ("NOTIF" + i),
          userId: rUserId,
          title: title,
          message: message,
          type: type || "general",
          date: dateStr,
          isRead: isReadBool
        });
      }
    }

    // Sort descending by date/id
    notifications.reverse();

    return jsonResponse({
      success: true,
      notifications: notifications,
      unreadCount: unreadCount
    });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error loading notifications: " + err.toString() });
  }
}

function markNotificationRead(e) {
  try {
    var ss;
    var params;

    if (e && typeof e.getSheetByName === "function") {
      ss = e;
      params = arguments[1] || {};
    } else {
      ss = (typeof SpreadsheetApp !== "undefined") ? SpreadsheetApp.getActiveSpreadsheet() : null;
      params = (e && e.parameter) ? e.parameter : (e || {});
    }

    var userId = (params.userId || params.userid || "").toString().trim();
    var notificationId = (params.notificationId || params.id || "").toString().trim();

    if (!userId) {
      return jsonResponse({ success: false, message: "User ID is required" });
    }

    if (!ss) {
      return jsonResponse({ success: false, message: "Spreadsheet context missing" });
    }

    var sheet = ss.getSheetByName("Notifications");
    if (!sheet) {
      return jsonResponse({ success: true, message: "No notifications sheet found" });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: true, message: "No notifications found" });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var notifIdCol = headers.indexOf("notification id");
    if (notifIdCol === -1) notifIdCol = headers.indexOf("notificationid");
    if (notifIdCol === -1) notifIdCol = 0;

    var userIdCol = headers.indexOf("user id");
    if (userIdCol === -1) userIdCol = headers.indexOf("userid");
    if (userIdCol === -1) userIdCol = 1;

    var statusCol = headers.indexOf("status");
    if (statusCol === -1) statusCol = headers.indexOf("isread");
    if (statusCol === -1) statusCol = 6;

    var isMarkAll = (notificationId.toLowerCase() === "all" || notificationId.toLowerCase() === "mark_all_read");

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var rUserId = row[userIdCol] ? row[userIdCol].toString().trim().toLowerCase() : "";
      var rNotifId = row[notifIdCol] ? row[notifIdCol].toString().trim().toLowerCase() : "";

      var matchesUser = (rUserId === userId.toLowerCase()) || (rUserId === "all");

      if (matchesUser) {
        if (isMarkAll || rNotifId === notificationId.toLowerCase()) {
          sheet.getRange(i + 1, statusCol + 1).setValue("read");
        }
      }
    }

    return jsonResponse({ success: true, message: "Notification status updated" });
  } catch (err) {
    return jsonResponse({ success: false, message: "Failed to update notification status: " + err.toString() });
  }
}

// Company Module Functions
function handlePostJob(ss, params) {
  try {
    var sheet = ss.getSheetByName("Jobs");
    if (!sheet) {
      sheet = ss.insertSheet("Jobs");
      sheet.appendRow(["Job ID", "Title", "Company", "Location", "Job Type", "Skills", "Salary", "Description", "Status", "Posted Date"]);
    }

    var company = (params.company || params.companyName || params.userId || "").toString().trim();
    var title = (params.title || params.jobTitle || "").toString().trim();
    var location = (params.location || "").toString().trim();
    var jobType = (params.jobType || params.type || "Full-time").toString().trim();
    var skills = (params.skills || params.requiredSkills || "").toString().trim();
    var salary = (params.salary || params.stipend || "").toString().trim();
    var description = (params.description || params.jobDescription || "").toString().trim();

    if (!title || !company) {
      return jsonResponse({ success: false, message: "Title and Company are required" });
    }

    var jobId = "JOB" + new Date().getTime();
    var postedDate = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");

    sheet.appendRow([jobId, title, company, location, jobType, skills, salary, description, "Active", postedDate]);

    return jsonResponse({
      success: true,
      message: "Job posted successfully",
      jobId: jobId
    });
  } catch (err) {
    return jsonResponse({ success: false, message: "Failed to post job: " + err.toString() });
  }
}

function handleGetCompanyApplications(ss, params) {
  try {
    var companyId = (params.companyId || params.company || params.userId || "").toString().trim().toLowerCase();

    var jobsMap = {};
    var companyJobIds = [];
    var jobsSheet = ss.getSheetByName("Jobs");
    if (jobsSheet) {
      var jobsData = jobsSheet.getDataRange().getValues();
      if (jobsData.length > 1) {
        var jobHeaders = jobsData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getJobVal = function (jRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = jobHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && jRow[idx] !== undefined && jRow[idx] !== null) {
              return jRow[idx].toString().trim();
            }
          }
          return "";
        };

        for (var j = 1; j < jobsData.length; j++) {
          var jRow = jobsData[j];
          var jId = getJobVal(jRow, ["jobid", "id", "job id"]);
          var jComp = getJobVal(jRow, ["company", "companyname", "company id", "companyid"]);
          if (jId) {
            jobsMap[jId.toLowerCase()] = {
              title: getJobVal(jRow, ["title", "jobtitle", "job title"]),
              company: jComp,
              location: getJobVal(jRow, ["location", "joblocation"]),
              salary: getJobVal(jRow, ["salary", "stipend"])
            };

            if (!companyId || companyId === "all" || jComp.toLowerCase().indexOf(companyId) !== -1 || companyId.indexOf(jComp.toLowerCase()) !== -1) {
              companyJobIds.push(jId.toLowerCase());
            }
          }
        }
      }
    }

    var profilesMap = {};
    var profSheet = ss.getSheetByName("StudentProfiles");
    if (profSheet) {
      var profData = profSheet.getDataRange().getValues();
      if (profData.length > 1) {
        var profHeaders = profData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getProfVal = function (pRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = profHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && pRow[idx] !== undefined && pRow[idx] !== null) {
              return pRow[idx].toString().trim();
            }
          }
          return "";
        };

        for (var p = 1; p < profData.length; p++) {
          var pRow = profData[p];
          var pUserId = getProfVal(pRow, ["user id", "userid", "student id"]);
          if (pUserId) {
            profilesMap[pUserId.toLowerCase()] = {
              name: getProfVal(pRow, ["name", "fullname", "student name"]),
              education: getProfVal(pRow, ["education", "branch", "degree"]),
              skills: getProfVal(pRow, ["skills"]),
              resumeUrl: getProfVal(pRow, ["resumeurl", "resume url", "resume"]),
              cgpa: getProfVal(pRow, ["cgpa", "marks"]),
              email: getProfVal(pRow, ["email", "emailaddress"]),
              mobile: getProfVal(pRow, ["mobile", "phone", "contact"])
            };
          }
        }
      }
    }

    var usersSheet = ss.getSheetByName("Users");
    if (usersSheet) {
      var usersData = usersSheet.getDataRange().getValues();
      if (usersData.length > 1) {
        var userHeaders = usersData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getUserVal = function (uRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = userHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && uRow[idx] !== undefined && uRow[idx] !== null) {
              return uRow[idx].toString().trim();
            }
          }
          return "";
        };

        for (var u = 1; u < usersData.length; u++) {
          var uRow = usersData[u];
          var uUserId = getUserVal(uRow, ["user id", "userid"]);
          if (uUserId) {
            var uLower = uUserId.toLowerCase();
            if (!profilesMap[uLower]) {
              profilesMap[uLower] = {};
            }
            if (!profilesMap[uLower].name) {
              profilesMap[uLower].name = getUserVal(uRow, ["name", "fullname"]);
            }
            if (!profilesMap[uLower].email) {
              profilesMap[uLower].email = getUserVal(uRow, ["email", "emailaddress"]);
            }
            if (!profilesMap[uLower].mobile) {
              profilesMap[uLower].mobile = getUserVal(uRow, ["mobile", "phone", "contact"]);
            }
          }
        }
      }
    }

    var appSheet = ss.getSheetByName("Applications");
    if (!appSheet) {
      return jsonResponse({ success: true, applications: [] });
    }

    var appData = appSheet.getDataRange().getValues();
    if (appData.length <= 1) {
      return jsonResponse({ success: true, applications: [] });
    }

    var appHeaders = appData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
    var getAppVal = function (row, names) {
      for (var k = 0; k < names.length; k++) {
        var idx = appHeaders.indexOf(names[k].toLowerCase());
        if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
          return row[idx].toString().trim();
        }
      }
      return "";
    };

    var applications = [];
    for (var i = 1; i < appData.length; i++) {
      var row = appData[i];
      var jobId = getAppVal(row, ["job id", "jobid"]);
      var jIdLower = jobId.toLowerCase();

      var isCompanyJob = !companyId || companyId === "all" || companyJobIds.indexOf(jIdLower) !== -1;
      if (!isCompanyJob && jobsMap[jIdLower]) {
        var jComp = (jobsMap[jIdLower].company || "").toLowerCase();
        if (jComp && (jComp.indexOf(companyId) !== -1 || companyId.indexOf(jComp) !== -1)) {
          isCompanyJob = true;
        }
      }

      if (isCompanyJob) {
        var appId = getAppVal(row, ["application id", "applicationid", "appid", "id"]);
        var userId = getAppVal(row, ["user id", "userid"]);
        var appliedDate = getAppVal(row, ["applied date", "applieddate", "date"]);
        var status = getAppVal(row, ["status", "applicationstatus"]);

        var jobDetails = jobsMap[jIdLower] || {};
        var profDetails = profilesMap[userId.toLowerCase()] || {};

        applications.push({
          applicationId: appId || ("APP" + i),
          jobId: jobId,
          userId: userId,
          studentName: profDetails.name || userId,
          email: profDetails.email || "",
          mobile: profDetails.mobile || "",
          appliedDate: appliedDate,
          status: status || "Applied",
          title: jobDetails.title || "",
          company: jobDetails.company || "",
          location: jobDetails.location || "",
          salary: jobDetails.salary || "",
          cgpa: profDetails.cgpa || "",
          education: profDetails.education || "",
          skills: profDetails.skills || "",
          resumeUrl: profDetails.resumeUrl || ""
        });
      }
    }

    return jsonResponse({ success: true, applications: applications });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error loading company applications: " + err.toString() });
  }
}

function handleUpdateApplicationStatus(ss, params) {
  try {
    var appIdReq = (params.applicationId || params.id || "").toString().trim().toLowerCase();
    var newStatus = (params.status || params.applicationStatus || "").toString().trim();

    if (!appIdReq || !newStatus) {
      return jsonResponse({ success: false, message: "Application ID and Status are required" });
    }

    var sheet = ss.getSheetByName("Applications");
    if (!sheet) {
      return jsonResponse({ success: false, message: "Applications sheet not found" });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: false, message: "No applications found" });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var appIdCol = headers.indexOf("application id");
    if (appIdCol === -1) appIdCol = headers.indexOf("applicationid");
    if (appIdCol === -1) appIdCol = 0;

    var statusCol = headers.indexOf("status");
    if (statusCol === -1) statusCol = headers.indexOf("applicationstatus");
    if (statusCol === -1) statusCol = 4;

    var userIdCol = headers.indexOf("user id");
    if (userIdCol === -1) userIdCol = headers.indexOf("userid");
    if (userIdCol === -1) userIdCol = 2;

    var jobIdCol = headers.indexOf("job id");
    if (jobIdCol === -1) jobIdCol = headers.indexOf("jobid");
    if (jobIdCol === -1) jobIdCol = 1;

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var rAppId = row[appIdCol] ? row[appIdCol].toString().trim().toLowerCase() : "";

      if (rAppId === appIdReq) {
        sheet.getRange(i + 1, statusCol + 1).setValue(newStatus);

        var rUserId = row[userIdCol] ? row[userIdCol].toString().trim() : "";
        var rJobId = row[jobIdCol] ? row[jobIdCol].toString().trim() : "";

        if (rUserId) {
          addNotification(ss, rUserId, "Application Status Updated", "Your application status for Job " + rJobId + " has been updated to " + newStatus + ".", "application");
        }

        return jsonResponse({ success: true, message: "Application status updated successfully" });
      }
    }

    return jsonResponse({ success: false, message: "Application not found" });
  } catch (err) {
    return jsonResponse({ success: false, message: "Failed to update status: " + err.toString() });
  }
}

// Phase 13 Recruiter Feedback Functions
function handleSubmitRecruiterFeedback(ss, params) {
  try {
    var feedbackId = (params.feedbackId || params.id || ("FB" + new Date().getTime())).toString().trim();
    var applicationId = (params.applicationId || params.application_id || "").toString().trim();
    var jobId = (params.jobId || params.job_id || "").toString().trim();
    var studentId = (params.studentId || params.userId || params.user_id || "").toString().trim();
    var companyId = (params.companyId || params.company_id || "").toString().trim();
    var rating = parseFloat(params.rating || "0");
    var feedback = (params.feedback || params.comment || "").toString().trim();
    var createdAt = (params.createdAt || params.created_at || new Date().toISOString().split('T')[0]).toString().trim();

    if (!applicationId && !jobId) {
      return jsonResponse({ success: false, message: "Application ID or Job ID is required" });
    }

    var sheetName = "RecruiterFeedback";
    var sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      sheet = ss.insertSheet(sheetName);
      sheet.appendRow([
        "Feedback ID",
        "Application ID",
        "Job ID",
        "Student ID",
        "Company ID",
        "Rating",
        "Feedback",
        "Created At"
      ]);
    }

    var data = sheet.getDataRange().getValues();
    var updated = false;

    if (data.length > 1 && applicationId) {
      var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });
      var appIdCol = headers.indexOf("application id");
      if (appIdCol === -1) appIdCol = headers.indexOf("applicationid");

      if (appIdCol !== -1) {
        for (var i = 1; i < data.length; i++) {
          var rAppId = data[i][appIdCol] ? data[i][appIdCol].toString().trim().toLowerCase() : "";
          if (rAppId === applicationId.toLowerCase()) {
            sheet.getRange(i + 1, 1, 1, 8).setValues([[
              feedbackId,
              applicationId,
              jobId,
              studentId,
              companyId,
              rating,
              feedback,
              createdAt
            ]]);
            updated = true;
            break;
          }
        }
      }
    }

    if (!updated) {
      sheet.appendRow([
        feedbackId,
        applicationId,
        jobId,
        studentId,
        companyId,
        rating,
        feedback,
        createdAt
      ]);
    }

    return jsonResponse({
      success: true,
      message: "Recruiter feedback saved successfully",
      feedbackId: feedbackId
    });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error saving feedback: " + err.toString() });
  }
}

function handleGetRecruiterFeedback(ss, params) {
  try {
    var sheetName = "RecruiterFeedback";
    var sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      return jsonResponse({ success: true, feedbackList: [] });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: true, feedbackList: [] });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var reqCompanyId = (params.companyId || params.company || "").toString().trim().toLowerCase();
    var reqJobId = (params.jobId || params.job || "").toString().trim().toLowerCase();
    var reqStudentId = (params.studentId || params.userId || "").toString().trim().toLowerCase();
    var reqAppId = (params.applicationId || params.id || "").toString().trim().toLowerCase();

    var feedbackList = [];

    for (var i = 1; i < data.length; i++) {
      var row = data[i];

      var getVal = function (names) {
        for (var k = 0; k < names.length; k++) {
          var idx = headers.indexOf(names[k].toLowerCase());
          if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
            return row[idx].toString().trim();
          }
        }
        return "";
      };

      var fId = getVal(["feedback id", "feedbackid", "id"]);
      var appId = getVal(["application id", "applicationid", "appid"]);
      var jId = getVal(["job id", "jobid"]);
      var sId = getVal(["student id", "studentid", "user id", "userid"]);
      var cId = getVal(["company id", "companyid"]);
      var rating = parseFloat(getVal(["rating"]) || "0");
      var comment = getVal(["feedback", "comment"]);
      var createdAt = getVal(["created at", "createdat", "date"]);

      if (reqCompanyId && cId.toLowerCase() !== reqCompanyId && cId.toLowerCase().indexOf(reqCompanyId) === -1) {
        continue;
      }
      if (reqJobId && jId.toLowerCase() !== reqJobId) {
        continue;
      }
      if (reqStudentId && sId.toLowerCase() !== reqStudentId) {
        continue;
      }
      if (reqAppId && appId.toLowerCase() !== reqAppId) {
        continue;
      }

      feedbackList.push({
        feedbackId: fId || ("FB" + i),
        applicationId: appId,
        jobId: jId,
        studentId: sId,
        companyId: cId,
        rating: rating,
        feedback: comment,
        createdAt: createdAt
      });
    }

    return jsonResponse({ success: true, feedbackList: feedbackList });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error fetching feedback: " + err.toString() });
  }
}

// Phase 14 Admin Statistics Function
function handleGetAdminStatistics(ss, params) {
  try {
    var totalStudents = 0;
    var totalJobs = 0;
    var totalApplications = 0;
    var shortlisted = 0;
    var selected = 0;

    // 1. Users Sheet - Count Student Users Only (Do not count Admin or Company)
    var usersSheet = ss.getSheetByName("Users");
    if (usersSheet) {
      var uData = usersSheet.getDataRange().getValues();
      if (uData.length > 1) {
        var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var roleCol = uHeaders.indexOf("role");
        if (roleCol === -1) roleCol = uHeaders.indexOf("user role");
        if (roleCol === -1) roleCol = uHeaders.indexOf("userrole");
        if (roleCol === -1) roleCol = uHeaders.indexOf("role name");
        if (roleCol === -1) roleCol = 4; // Fallback to column index 4 (0-based) as per Users sheet schema

        for (var i = 1; i < uData.length; i++) {
          var uRow = uData[i];
          if (!uRow[0] && !uRow[1]) continue; // Skip empty rows

          var roleVal = (roleCol !== -1 && uRow[roleCol] !== undefined && uRow[roleCol] !== null)
            ? String(uRow[roleCol]).trim().toLowerCase()
            : "";

          if (roleVal === "student") {
            totalStudents++;
          }
        }
      }
    }

    // 2. Jobs Sheet - Count Total Active Jobs
    var jobsSheet = ss.getSheetByName("Jobs");
    if (jobsSheet) {
      var jData = jobsSheet.getDataRange().getValues();
      if (jData.length > 1) {
        var jHeaders = jData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var statusCol = jHeaders.indexOf("status");
        if (statusCol === -1) statusCol = jHeaders.indexOf("job status");
        if (statusCol === -1) statusCol = jHeaders.indexOf("jobstatus");

        for (var j = 1; j < jData.length; j++) {
          var jRow = jData[j];
          if (!jRow[0] && !jRow[1]) continue; // Skip empty rows

          var jStatus = (statusCol !== -1 && jRow[statusCol] !== undefined && jRow[statusCol] !== null)
            ? String(jRow[statusCol]).trim().toLowerCase()
            : "active";

          if (!jStatus || jStatus === "active" || jStatus === "open") {
            totalJobs++;
          }
        }
      }
    }

    // 3. Applications Sheet - Count Applications, Shortlisted & Selected
    var appsSheet = ss.getSheetByName("Applications");
    if (appsSheet) {
      var aData = appsSheet.getDataRange().getValues();
      if (aData.length > 1) {
        var aHeaders = aData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var aStatusCol = aHeaders.indexOf("status");
        if (aStatusCol === -1) aStatusCol = aHeaders.indexOf("application status");
        if (aStatusCol === -1) aStatusCol = aHeaders.indexOf("applicationstatus");
        if (aStatusCol === -1) aStatusCol = 4; // Fallback to column index 4

        for (var k = 1; k < aData.length; k++) {
          var aRow = aData[k];
          if (!aRow[0] && !aRow[1] && !aRow[2]) continue; // Skip empty rows

          totalApplications++;

          var aStatus = (aStatusCol !== -1 && aRow[aStatusCol] !== undefined && aRow[aStatusCol] !== null)
            ? String(aRow[aStatusCol]).trim().toLowerCase()
            : "";

          if (aStatus.indexOf("shortlist") !== -1) {
            shortlisted++;
          }
          if (aStatus.indexOf("select") !== -1 || aStatus.indexOf("hired") !== -1 || aStatus.indexOf("accepted") !== -1) {
            selected++;
          }
        }
      }
    }

    var placementPercentage = totalApplications > 0
      ? parseFloat(((selected / totalApplications) * 100).toFixed(1))
      : 0.0;

    return jsonResponse({
      success: true,
      totalStudents: totalStudents,
      totalJobs: totalJobs,
      totalApplications: totalApplications,
      shortlisted: shortlisted,
      selected: selected,
      placementPercentage: placementPercentage
    });
  } catch (err) {
    return jsonResponse({
      success: false,
      message: "Error generating admin statistics: " + err.toString()
    });
  }
}

// Phase 14B - Get Admin Companies
function handleGetAdminCompanies(ss, params) {
  try {
    var usersSheet = ss.getSheetByName("Users");
    if (!usersSheet) {
      return jsonResponse({ success: true, companies: [] });
    }

    var uData = usersSheet.getDataRange().getValues();
    if (uData.length <= 1) {
      return jsonResponse({ success: true, companies: [] });
    }

    var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var userIdCol = uHeaders.indexOf("user id");
    if (userIdCol === -1) userIdCol = uHeaders.indexOf("userid");
    if (userIdCol === -1) userIdCol = 0;

    var nameCol = uHeaders.indexOf("name");
    if (nameCol === -1) nameCol = uHeaders.indexOf("fullname");
    if (nameCol === -1) nameCol = uHeaders.indexOf("company name");
    if (nameCol === -1) nameCol = 1;

    var emailCol = uHeaders.indexOf("email");
    if (emailCol === -1) emailCol = uHeaders.indexOf("email address");
    if (emailCol === -1) emailCol = 2;

    var roleCol = uHeaders.indexOf("role");
    if (roleCol === -1) roleCol = uHeaders.indexOf("user role");
    if (roleCol === -1) roleCol = uHeaders.indexOf("userrole");
    if (roleCol === -1) roleCol = 4;

    var statusCol = uHeaders.indexOf("status");
    if (statusCol === -1) statusCol = uHeaders.indexOf("user status");
    if (statusCol === -1) statusCol = 5;

    var companies = [];

    for (var i = 1; i < uData.length; i++) {
      var row = uData[i];
      if (!row[0] && !row[1]) continue;

      var roleVal = (roleCol !== -1 && row[roleCol] !== undefined && row[roleCol] !== null)
        ? String(row[roleCol]).trim().toLowerCase()
        : "";

      if (roleVal === "company" || roleVal === "hr" || roleVal === "recruiter") {
        var uId = (userIdCol !== -1 && row[userIdCol] !== undefined && row[userIdCol] !== null)
          ? String(row[userIdCol]).trim()
          : "";
        var uName = (nameCol !== -1 && row[nameCol] !== undefined && row[nameCol] !== null)
          ? String(row[nameCol]).trim()
          : "";
        var uEmail = (emailCol !== -1 && row[emailCol] !== undefined && row[emailCol] !== null)
          ? String(row[emailCol]).trim()
          : "";
        var uStatus = (statusCol !== -1 && row[statusCol] !== undefined && row[statusCol] !== null)
          ? String(row[statusCol]).trim()
          : "Active";

        companies.push({
          userId: uId || ("COM" + i),
          name: uName || uId,
          email: uEmail,
          status: uStatus || "Active",
          role: "Company"
        });
      }
    }

    return jsonResponse({ success: true, companies: companies });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error loading company accounts: " + err.toString() });
  }
}

// Phase 14B - Update Company Status
function handleUpdateCompanyStatus(ss, params) {
  try {
    var userIdReq = (params.userId || params.userid || params.companyId || "").toString().trim().toLowerCase();
    var newStatus = (params.status || "").toString().trim();

    if (!userIdReq || !newStatus) {
      return jsonResponse({ success: false, message: "User ID and Status are required" });
    }

    var usersSheet = ss.getSheetByName("Users");
    if (!usersSheet) {
      return jsonResponse({ success: false, message: "Users sheet not found" });
    }

    var data = usersSheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: false, message: "No user accounts found" });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var userIdCol = headers.indexOf("user id");
    if (userIdCol === -1) userIdCol = headers.indexOf("userid");
    if (userIdCol === -1) userIdCol = 0;

    var statusCol = headers.indexOf("status");
    if (statusCol === -1) statusCol = headers.indexOf("user status");
    if (statusCol === -1) statusCol = 5;

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var rUserId = row[userIdCol] ? String(row[userIdCol]).trim().toLowerCase() : "";

      if (rUserId === userIdReq) {
        usersSheet.getRange(i + 1, statusCol + 1).setValue(newStatus);
        return jsonResponse({
          success: true,
          message: "Company status updated successfully",
          userId: row[userIdCol],
          status: newStatus
        });
      }
    }

    return jsonResponse({ success: false, message: "Company account not found" });
  } catch (err) {
    return jsonResponse({ success: false, message: "Failed to update company status: " + err.toString() });
  }
}

// Phase 15 Functions: Analytics & Reports

function handleGetMostDemandedSkills(ss, params) {
  try {
    var sheet = ss.getSheetByName("Jobs");
    if (!sheet) {
      return jsonResponse({ success: true, skills: [] });
    }
    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({ success: true, skills: [] });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });
    var skillsCol = headers.indexOf("skills");
    if (skillsCol === -1) skillsCol = headers.indexOf("requiredskills");
    if (skillsCol === -1) skillsCol = headers.indexOf("skillsrequired");
    if (skillsCol === -1) skillsCol = headers.indexOf("required skills");
    if (skillsCol === -1) skillsCol = 5;

    var skillCounts = {};
    var skillDisplayMap = {};

    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      if (!row[0] && !row[1]) continue;

      var status = "";
      var statusCol = headers.indexOf("status");
      if (statusCol === -1) statusCol = headers.indexOf("jobstatus");
      if (statusCol !== -1 && row[statusCol] !== undefined && row[statusCol] !== null) {
        status = row[statusCol].toString().trim().toLowerCase();
      }
      if (status && status !== "active" && status !== "open") {
        continue;
      }

      var rawSkills = (row[skillsCol] !== undefined && row[skillsCol] !== null)
        ? row[skillsCol].toString().trim()
        : "";

      if (!rawSkills) continue;

      var splitTokens = rawSkills.split(/[,/;\n|]/);
      for (var k = 0; k < splitTokens.length; k++) {
        var token = splitTokens[k].trim();
        if (token.length > 0) {
          var canonical = token.toLowerCase();
          if (!skillDisplayMap[canonical]) {
            skillDisplayMap[canonical] = token;
          }
          skillCounts[canonical] = (skillCounts[canonical] || 0) + 1;
        }
      }
    }

    var resultList = [];
    for (var key in skillCounts) {
      resultList.push({
        skill: skillDisplayMap[key] || key,
        count: skillCounts[key]
      });
    }

    resultList.sort(function (a, b) {
      return b.count - a.count;
    });

    return jsonResponse({ success: true, skills: resultList });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error fetching demanded skills: " + err.toString() });
  }
}

function handleGetReadinessDistribution(ss, params) {
  try {
    var jobsSheet = ss.getSheetByName("Jobs");
    var activeJobs = [];
    if (jobsSheet) {
      var jData = jobsSheet.getDataRange().getValues();
      if (jData.length > 1) {
        var jHeaders = jData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var jSkillsCol = jHeaders.indexOf("skills");
        if (jSkillsCol === -1) jSkillsCol = jHeaders.indexOf("requiredskills");
        if (jSkillsCol === -1) jSkillsCol = 5;

        for (var j = 1; j < jData.length; j++) {
          var jRow = jData[j];
          var jStatusCol = jHeaders.indexOf("status");
          var jStatus = (jStatusCol !== -1 && jRow[jStatusCol] !== undefined)
            ? jRow[jStatusCol].toString().trim().toLowerCase()
            : "active";
          if (!jStatus || jStatus === "active" || jStatus === "open") {
            var rawSkills = jRow[jSkillsCol] ? jRow[jSkillsCol].toString().trim() : "";
            activeJobs.push(rawSkills);
          }
        }
      }
    }

    var studentMap = {};
    var profSheet = ss.getSheetByName("StudentProfiles");
    if (profSheet) {
      var pData = profSheet.getDataRange().getValues();
      if (pData.length > 1) {
        var pHeaders = pData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getPVal = function (pRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = pHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && pRow[idx] !== undefined && pRow[idx] !== null) {
              return pRow[idx].toString().trim();
            }
          }
          return "";
        };

        for (var p = 1; p < pData.length; p++) {
          var pRow = pData[p];
          var uId = getPVal(pRow, ["user id", "userid", "student id"]);
          if (uId) {
            studentMap[uId.toLowerCase()] = {
              userId: uId,
              name: getPVal(pRow, ["name", "fullname", "student name"]),
              email: getPVal(pRow, ["email"]),
              mobile: getPVal(pRow, ["mobile", "phone"]),
              education: getPVal(pRow, ["education", "branch", "degree"]),
              github: getPVal(pRow, ["github"]),
              linkedin: getPVal(pRow, ["linkedin"]),
              skills: getPVal(pRow, ["skills"]),
              projects: getPVal(pRow, ["projects"]),
              certifications: getPVal(pRow, ["certifications"])
            };
          }
        }
      }
    }

    var usersSheet = ss.getSheetByName("Users");
    if (usersSheet) {
      var uData = usersSheet.getDataRange().getValues();
      if (uData.length > 1) {
        var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var uRoleCol = uHeaders.indexOf("role");
        if (uRoleCol === -1) uRoleCol = 4;
        var uIdCol = uHeaders.indexOf("user id");
        if (uIdCol === -1) uIdCol = 0;
        var uNameCol = uHeaders.indexOf("name");
        if (uNameCol === -1) uNameCol = 1;

        for (var u = 1; u < uData.length; u++) {
          var uRow = uData[u];
          var roleVal = (uRoleCol !== -1 && uRow[uRoleCol]) ? uRow[uRoleCol].toString().trim().toLowerCase() : "";
          if (roleVal === "student") {
            var userIdVal = uRow[uIdCol] ? uRow[uIdCol].toString().trim() : "";
            if (userIdVal && !studentMap[userIdVal.toLowerCase()]) {
              studentMap[userIdVal.toLowerCase()] = {
                userId: userIdVal,
                name: uRow[uNameCol] ? uRow[uNameCol].toString().trim() : "",
                email: "",
                mobile: "",
                education: "",
                github: "",
                linkedin: "",
                skills: "",
                projects: "",
                certifications: ""
              };
            }
          }
        }
      }
    }

    var counts = {
      "Ready": 0,
      "Almost Ready": 0,
      "Needs Improvement": 0
    };

    for (var key in studentMap) {
      var s = studentMap[key];
      var compScore = 0.0;
      if (s.name) compScore += 6.67;
      if (s.email) compScore += 6.67;
      if (s.mobile) compScore += 6.66;
      if (s.education) compScore += 15.0;
      if (s.github) compScore += 7.5;
      if (s.linkedin) compScore += 7.5;

      var sSkillList = s.skills ? s.skills.split(/[,/;\n|]/).map(function(sk){ return sk.trim().toLowerCase(); }).filter(function(sk){ return sk.length > 0; }) : [];
      if (sSkillList.length >= 5) compScore += 25.0;
      else if (sSkillList.length >= 3) compScore += 18.0;
      else if (sSkillList.length >= 1) compScore += 10.0;

      if (s.projects) compScore += 15.0;
      if (s.certifications) compScore += 10.0;
      if (compScore > 100.0) compScore = 100.0;

      var mktScore = 100.0;
      if (activeJobs.length > 0) {
        var totalMatchSum = 0.0;
        for (var jIdx = 0; jIdx < activeJobs.length; jIdx++) {
          var jobSkillStr = activeJobs[jIdx];
          var reqSkills = jobSkillStr ? jobSkillStr.split(/[,/;\n|]/).map(function(sk){ return sk.trim().toLowerCase(); }).filter(function(sk){ return sk.length > 0; }) : [];
          if (reqSkills.length === 0) {
            totalMatchSum += 100.0;
          } else {
            var matched = 0;
            for (var r = 0; r < reqSkills.length; r++) {
              if (sSkillList.indexOf(reqSkills[r]) !== -1) {
                matched++;
              }
            }
            totalMatchSum += (matched / reqSkills.length) * 100.0;
          }
        }
        mktScore = totalMatchSum / activeJobs.length;
      }

      var overall = (compScore * 0.50) + (mktScore * 0.50);

      if (overall >= 80.0) {
        counts["Ready"]++;
      } else if (overall >= 50.0) {
        counts["Almost Ready"]++;
      } else {
        counts["Needs Improvement"]++;
      }
    }

    var categories = [
      { category: "Ready", count: counts["Ready"] },
      { category: "Almost Ready", count: counts["Almost Ready"] },
      { category: "Needs Improvement", count: counts["Needs Improvement"] }
    ];

    return jsonResponse({ success: true, categories: categories });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error calculating readiness distribution: " + err.toString() });
  }
}

function handleGetTopRecommendedJobs(ss, params) {
  try {
    var jobsSheet = ss.getSheetByName("Jobs");
    if (!jobsSheet) {
      return jsonResponse({ success: true, recommendedJobs: [], jobs: [] });
    }

    var jData = jobsSheet.getDataRange().getValues();
    if (jData.length <= 1) {
      return jsonResponse({ success: true, recommendedJobs: [], jobs: [] });
    }

    var jHeaders = jData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
    var getJVal = function (row, names) {
      for (var k = 0; k < names.length; k++) {
        var idx = jHeaders.indexOf(names[k].toLowerCase());
        if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
          return row[idx].toString().trim();
        }
      }
      return "";
    };

    var jobsList = [];
    for (var j = 1; j < jData.length; j++) {
      var jRow = jData[j];
      var jId = getJVal(jRow, ["jobid", "id", "job id"]);
      var status = getJVal(jRow, ["status", "jobstatus"]);
      if (status && status.toLowerCase() !== "active" && status.toLowerCase() !== "open") {
        continue;
      }
      if (jId || getJVal(jRow, ["title", "jobtitle", "job title"])) {
        jobsList.push({
          jobId: jId || ("JOB" + j),
          title: getJVal(jRow, ["title", "jobtitle", "job title"]),
          company: getJVal(jRow, ["company", "companyname", "company name"]),
          skills: getJVal(jRow, ["skills", "requiredskills", "skillsrequired"])
        });
      }
    }

    var studentSkillsList = [];
    var profSheet = ss.getSheetByName("StudentProfiles");
    if (profSheet) {
      var pData = profSheet.getDataRange().getValues();
      if (pData.length > 1) {
        var pHeaders = pData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var sCol = pHeaders.indexOf("skills");
        for (var p = 1; p < pData.length; p++) {
          var pSkills = (sCol !== -1 && pData[p][sCol]) ? pData[p][sCol].toString().trim() : "";
          var tokens = pSkills.split(/[,/;\n|]/).map(function(sk){ return sk.trim().toLowerCase(); }).filter(function(sk){ return sk.length > 0; });
          studentSkillsList.push(tokens);
        }
      }
    }

    var recCounts = {};
    var avgMatchMap = {};
    var missingSkillsMap = {};

    for (var i = 0; i < jobsList.length; i++) {
      var job = jobsList[i];
      var reqSkills = job.skills.split(/[,/;\n|]/).map(function(sk){ return sk.trim().toLowerCase(); }).filter(function(sk){ return sk.length > 0; });

      var count = 0;
      var totalMatchPct = 0;

      for (var s = 0; s < studentSkillsList.length; s++) {
        var stSkills = studentSkillsList[s];
        if (reqSkills.length === 0) {
          count++;
          totalMatchPct += 100;
        } else {
          var matched = 0;
          for (var r = 0; r < reqSkills.length; r++) {
            if (stSkills.indexOf(reqSkills[r]) !== -1) {
              matched++;
            }
          }
          var matchPct = (matched / reqSkills.length) * 100.0;
          totalMatchPct += matchPct;
          if (matchPct >= 50.0) {
            count++;
          }
        }
      }

      recCounts[job.jobId] = count;
      avgMatchMap[job.jobId] = studentSkillsList.length > 0 ? Math.round(totalMatchPct / studentSkillsList.length) : 0;
      missingSkillsMap[job.jobId] = reqSkills.join(", ");
    }

    var resultList = [];
    for (var k = 0; k < jobsList.length; k++) {
      var jb = jobsList[k];
      resultList.push({
        jobId: jb.jobId,
        jobTitle: jb.title,
        title: jb.title,
        company: jb.company,
        recommendationCount: recCounts[jb.jobId] || 0,
        matchPercentage: avgMatchMap[jb.jobId] || 0,
        missingSkills: missingSkillsMap[jb.jobId] || ""
      });
    }

    resultList.sort(function (a, b) {
      return b.recommendationCount - a.recommendationCount;
    });

    return jsonResponse({
      success: true,
      recommendedJobs: resultList,
      jobs: resultList
    });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error fetching recommended jobs: " + err.toString() });
  }
}

function handleGetPlacementTrends(ss, params) {
  try {
    var appSheet = ss.getSheetByName("Applications");
    if (!appSheet) {
      return jsonResponse({ success: true, trends: [] });
    }

    var aData = appSheet.getDataRange().getValues();
    if (aData.length <= 1) {
      return jsonResponse({ success: true, trends: [] });
    }

    var aHeaders = aData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
    var dateCol = aHeaders.indexOf("applied date");
    if (dateCol === -1) dateCol = aHeaders.indexOf("applieddate");
    if (dateCol === -1) dateCol = aHeaders.indexOf("date");
    if (dateCol === -1) dateCol = 3;

    var statusCol = aHeaders.indexOf("status");
    if (statusCol === -1) statusCol = aHeaders.indexOf("applicationstatus");
    if (statusCol === -1) statusCol = 4;

    var monthMap = {};

    var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    for (var i = 1; i < aData.length; i++) {
      var row = aData[i];
      if (!row[0] && !row[1] && !row[2]) continue;

      var rawDate = row[dateCol];
      var dateObj = null;

      if (rawDate instanceof Date && !isNaN(rawDate.getTime())) {
        dateObj = rawDate;
      } else if (rawDate) {
        var strDate = rawDate.toString().trim();
        var parsed = Date.parse(strDate);
        if (!isNaN(parsed)) {
          dateObj = new Date(parsed);
        } else {
          var parts = strDate.split(" ")[0].split("-");
          if (parts.length >= 3) {
            var y = parseInt(parts[0], 10);
            var m = parseInt(parts[1], 10) - 1;
            var d = parseInt(parts[2], 10);
            if (!isNaN(y) && !isNaN(m) && !isNaN(d)) {
              dateObj = new Date(y, m, d);
            }
          }
        }
      }

      if (!dateObj) continue;

      var year = dateObj.getFullYear();
      var monthIdx = dateObj.getMonth();
      var sortKey = year + "-" + (monthIdx < 9 ? "0" + (monthIdx + 1) : (monthIdx + 1));
      var displayMonth = monthNames[monthIdx] + " " + year;

      if (!monthMap[sortKey]) {
        monthMap[sortKey] = {
          sortKey: sortKey,
          month: displayMonth,
          applications: 0,
          shortlisted: 0,
          placements: 0,
          selected: 0
        };
      }

      monthMap[sortKey].applications++;

      var status = (statusCol !== -1 && row[statusCol]) ? row[statusCol].toString().trim().toLowerCase() : "";
      if (status.indexOf("shortlist") !== -1) {
        monthMap[sortKey].shortlisted++;
      }
      if (status.indexOf("select") !== -1 || status.indexOf("hired") !== -1 || status.indexOf("accept") !== -1 || status.indexOf("place") !== -1) {
        monthMap[sortKey].placements++;
        monthMap[sortKey].selected++;
      }
    }

    var keys = [];
    for (var k in monthMap) {
      keys.push(k);
    }
    keys.sort();

    var trends = [];
    for (var m = 0; m < keys.length; m++) {
      trends.push({
        month: monthMap[keys[m]].month,
        applications: monthMap[keys[m]].applications,
        shortlisted: monthMap[keys[m]].shortlisted,
        placements: monthMap[keys[m]].placements,
        selected: monthMap[keys[m]].selected
      });
    }

    return jsonResponse({ success: true, trends: trends });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error calculating placement trends: " + err.toString() });
  }
}

// Phase 14 Admin Students Handler
function handleGetAdminStudents(ss, params) {
  try {
    var usersSheet = ss.getSheetByName("Users");
    if (!usersSheet) {
      return jsonResponse({ success: true, students: [] });
    }
    var uData = usersSheet.getDataRange().getValues();
    if (uData.length <= 1) {
      return jsonResponse({ success: true, students: [] });
    }
    var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });

    var userIdCol = uHeaders.indexOf("user id");
    if (userIdCol === -1) userIdCol = uHeaders.indexOf("userid");
    if (userIdCol === -1) userIdCol = 0;

    var nameCol = uHeaders.indexOf("name");
    if (nameCol === -1) nameCol = uHeaders.indexOf("fullname");
    if (nameCol === -1) nameCol = 1;

    var emailCol = uHeaders.indexOf("email");
    if (emailCol === -1) emailCol = uHeaders.indexOf("emailaddress");
    if (emailCol === -1) emailCol = 2;

    var mobileCol = uHeaders.indexOf("mobile");
    if (mobileCol === -1) mobileCol = uHeaders.indexOf("phone");
    if (mobileCol === -1) mobileCol = 3;

    var roleCol = uHeaders.indexOf("role");
    if (roleCol === -1) roleCol = uHeaders.indexOf("user role");
    if (roleCol === -1) roleCol = uHeaders.indexOf("userrole");
    if (roleCol === -1) roleCol = uHeaders.indexOf("role name");
    if (roleCol === -1) roleCol = 4;

    var statusCol = uHeaders.indexOf("status");
    if (statusCol === -1) statusCol = uHeaders.indexOf("user status");
    if (statusCol === -1) statusCol = 5;

    var profMap = {};
    var profSheet = ss.getSheetByName("StudentProfiles");
    if (profSheet) {
      var pData = profSheet.getDataRange().getValues();
      if (pData.length > 1) {
        var pHeaders = pData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var getPVal = function(pRow, names) {
          for (var k = 0; k < names.length; k++) {
            var idx = pHeaders.indexOf(names[k].toLowerCase());
            if (idx !== -1 && pRow[idx] !== undefined && pRow[idx] !== null) return pRow[idx].toString().trim();
          }
          return "";
        };
        for (var p = 1; p < pData.length; p++) {
          var pRow = pData[p];
          var pId = getPVal(pRow, ["user id", "userid", "student id"]);
          if (pId) {
            profMap[pId.toLowerCase()] = {
              name: getPVal(pRow, ["name", "fullname", "student name"]),
              email: getPVal(pRow, ["email", "emailaddress"]),
              education: getPVal(pRow, ["education", "branch", "degree", "course"]),
              skills: getPVal(pRow, ["skills"]),
              mobile: getPVal(pRow, ["mobile", "phone", "contact"]),
              cgpa: getPVal(pRow, ["cgpa", "marks"]),
              semester: getPVal(pRow, ["semester", "sem", "year"]),
              resumeUrl: getPVal(pRow, ["resumeurl", "resume url", "resume"])
            };
          }
        }
      }
    }

    var students = [];
    var seenUserIds = {};

    for (var i = 1; i < uData.length; i++) {
      var row = uData[i];
      if (!row[0] && !row[1]) continue;

      var uId = (userIdCol !== -1 && row[userIdCol] !== undefined && row[userIdCol] !== null)
        ? String(row[userIdCol]).trim()
        : "";
      if (!uId) continue;

      var uIdLower = uId.toLowerCase();
      if (seenUserIds[uIdLower]) continue;

      var rRole = (roleCol !== -1 && row[roleCol] !== undefined && row[roleCol] !== null)
        ? String(row[roleCol]).trim().toLowerCase()
        : "";

      if (rRole === "student" || (rRole === "" && uId.toUpperCase().indexOf("STU") !== -1)) {
        seenUserIds[uIdLower] = true;

        var uName = (nameCol !== -1 && row[nameCol] !== undefined && row[nameCol] !== null) ? String(row[nameCol]).trim() : "";
        var uEmail = (emailCol !== -1 && row[emailCol] !== undefined && row[emailCol] !== null) ? String(row[emailCol]).trim() : "";
        var uMobile = (mobileCol !== -1 && row[mobileCol] !== undefined && row[mobileCol] !== null) ? String(row[mobileCol]).trim() : "";
        var uStatus = (statusCol !== -1 && row[statusCol] !== undefined && row[statusCol] !== null) ? String(row[statusCol]).trim() : "Active";

        var prof = profMap[uIdLower] || {};

        students.push({
          userId: uId,
          studentId: uId,
          name: uName || prof.name || uId,
          email: uEmail || prof.email || "",
          mobile: uMobile || prof.mobile || "",
          education: prof.education || "",
          course: prof.education || "",
          semester: prof.semester || "",
          skills: prof.skills || "",
          cgpa: prof.cgpa || "",
          resumeUrl: prof.resumeUrl || "",
          status: uStatus || "Active"
        });
      }
    }
    return jsonResponse({ success: true, students: students });
  } catch (err) {
    return jsonResponse({ success: false, message: "Error loading admin students: " + err.toString() });
  }
}


// ==========================================================
// PHASE 16 - SYSTEM BROADCAST & STUDENT MANAGEMENT HANDLERS
// ==========================================================

function handleSendBroadcast(spreadsheet, params) {
  try {
    var title = String(params.title || "").trim();
    var message = String(params.message || "").trim();
    var audience = String(params.audience || params.targetAudience || "all").trim().toLowerCase();
    var createdBy = String(params.createdBy || params.author || "Admin").trim();

    if (!title || !message) {
      return jsonResponse({
        success: false,
        message: "Title and message are required for broadcast."
      });
    }

    var sheet = spreadsheet.getSheetByName("Announcements");
    if (!sheet) {
      sheet = spreadsheet.insertSheet("Announcements");
      sheet.appendRow([
        "Broadcast ID",
        "Title",
        "Message",
        "Audience",
        "Created By",
        "Date",
        "Status"
      ]);
    }

    var broadcastId = "BC" + new Date().getTime();
    var tz = Session.getScriptTimeZone() || "GMT";
    var dateStr = Utilities.formatDate(new Date(), tz, "yyyy-MM-dd HH:mm");

    sheet.appendRow([
      broadcastId,
      title,
      message,
      audience,
      createdBy,
      dateStr,
      "Active"
    ]);

    // Push individual notifications to targeted users in Notifications sheet
    try {
      var usersSheet = spreadsheet.getSheetByName("Users");
      if (usersSheet) {
        var uData = usersSheet.getDataRange().getValues();
        if (uData.length > 1) {
          var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
          var uIdCol = uHeaders.indexOf("user id");
          if (uIdCol === -1) uIdCol = uHeaders.indexOf("userid");
          if (uIdCol === -1) uIdCol = 0;

          var roleCol = uHeaders.indexOf("role");
          if (roleCol === -1) roleCol = uHeaders.indexOf("user role");
          if (roleCol === -1) roleCol = 4;

          for (var i = 1; i < uData.length; i++) {
            var row = uData[i];
            var uId = row[uIdCol] ? String(row[uIdCol]).trim() : "";
            var uRole = (roleCol !== -1 && row[roleCol]) ? String(row[roleCol]).trim().toLowerCase() : "";
            if (!uId) continue;

            var matches = false;
            if (audience === "all" || audience === "" || audience === "all users") {
              matches = true;
            } else if ((audience === "student" || audience === "students") && (uRole === "student" || uRole === "student user" || uId.toUpperCase().indexOf("STU") !== -1)) {
              matches = true;
            } else if ((audience === "company" || audience === "companies" || audience === "recruiter" || audience === "recruiters") && (uRole === "company" || uRole === "recruiter" || uId.toUpperCase().indexOf("COM") !== -1)) {
              matches = true;
            }

            if (matches) {
              addNotification(spreadsheet, uId, "Broadcast: " + title, message, "broadcast");
            }
          }
        }
      }
    } catch (notifErr) {
      Logger.log("Failed to dispatch notifications for broadcast: " + notifErr.toString());
    }

    return jsonResponse({
      success: true,
      message: "Broadcast announcement sent successfully.",
      broadcastId: broadcastId
    });

  } catch (error) {
    return jsonResponse({
      success: false,
      message: "Failed to send broadcast: " + error.toString()
    });
  }
}

function handleGetBroadcasts(spreadsheet, params) {
  try {
    var sheet = spreadsheet.getSheetByName("Announcements");
    if (!sheet) {
      return jsonResponse({
        success: true,
        broadcasts: []
      });
    }

    var data = sheet.getDataRange().getValues();
    if (data.length <= 1) {
      return jsonResponse({
        success: true,
        broadcasts: []
      });
    }

    var headers = data[0].map(function (h) { return h.toString().trim().toLowerCase(); });
    var broadcasts = [];

    for (var i = data.length - 1; i >= 1; i--) {
      var row = data[i];
      var getVal = function (names) {
        for (var k = 0; k < names.length; k++) {
          var idx = headers.indexOf(names[k].toLowerCase());
          if (idx !== -1 && row[idx] !== undefined && row[idx] !== null) {
            return String(row[idx]).trim();
          }
        }
        return "";
      };

      var broadcastId = getVal(["broadcast id", "broadcastid", "id"]);
      var title = getVal(["title"]);
      var message = getVal(["message"]);
      var audience = getVal(["audience", "targetaudience"]);
      var createdBy = getVal(["created by", "createdby", "author"]);
      var dateStr = getVal(["date", "createdat", "timestamp"]);
      var status = getVal(["status"]);

      if (title || message) {
        broadcasts.push({
          broadcastId: broadcastId || ("BC" + i),
          title: title,
          message: message,
          audience: audience || "all",
          createdBy: createdBy || "Admin",
          date: dateStr,
          status: status || "Active"
        });
      }
    }

    return jsonResponse({
      success: true,
      broadcasts: broadcasts
    });

  } catch (error) {
    return jsonResponse({
      success: false,
      message: "Failed to fetch broadcasts: " + error.toString()
    });
  }
}

function handleDeleteStudent(spreadsheet, params) {
  try {
    var userId = String(params.userId || params.studentId || "").trim();
    if (!userId) {
      return jsonResponse({
        success: false,
        message: "Student User ID is required for deletion."
      });
    }

    var deletedUsers = 0;
    var deletedProfiles = 0;

    var usersSheet = spreadsheet.getSheetByName("Users");
    if (usersSheet) {
      var uData = usersSheet.getDataRange().getValues();
      if (uData.length > 1) {
        var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var uIdCol = uHeaders.indexOf("user id");
        if (uIdCol === -1) uIdCol = uHeaders.indexOf("userid");
        if (uIdCol === -1) uIdCol = uHeaders.indexOf("student id");
        if (uIdCol === -1) uIdCol = 0;

        for (var i = uData.length - 1; i >= 1; i--) {
          if (uData[i][uIdCol] && String(uData[i][uIdCol]).trim().toLowerCase() === userId.toLowerCase()) {
            usersSheet.deleteRow(i + 1);
            deletedUsers++;
          }
        }
      }
    }

    var profSheet = spreadsheet.getSheetByName("StudentProfiles");
    if (profSheet) {
      var pData = profSheet.getDataRange().getValues();
      if (pData.length > 1) {
        var pHeaders = pData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var pIdCol = pHeaders.indexOf("user id");
        if (pIdCol === -1) pIdCol = pHeaders.indexOf("userid");
        if (pIdCol === -1) pIdCol = pHeaders.indexOf("student id");
        if (pIdCol === -1) pIdCol = 0;

        for (var k = pData.length - 1; k >= 1; k--) {
          if (pData[k][pIdCol] && String(pData[k][pIdCol]).trim().toLowerCase() === userId.toLowerCase()) {
            profSheet.deleteRow(k + 1);
            deletedProfiles++;
          }
        }
      }
    }

    if (deletedUsers === 0 && deletedProfiles === 0) {
      return jsonResponse({
        success: false,
        message: "Student record (" + userId + ") was not found."
      });
    }

    return jsonResponse({
      success: true,
      message: "Student record (" + userId + ") deleted successfully."
    });

  } catch (error) {
    return jsonResponse({
      success: false,
      message: "Failed to delete student: " + error.toString()
    });
  }
}

function handleUpdateStudent(spreadsheet, params) {
  try {
    var userId = String(params.userId || params.studentId || "").trim();
    if (!userId) {
      return jsonResponse({
        success: false,
        message: "Student User ID is required for update."
      });
    }

    var name = params.name !== undefined ? String(params.name).trim() : null;
    var email = params.email !== undefined ? String(params.email).trim() : null;
    var mobile = params.mobile !== undefined ? String(params.mobile).trim() : null;
    var status = params.status !== undefined ? String(params.status).trim() : null;
    var education = params.education !== undefined ? String(params.education).trim() : null;
    var semester = params.semester !== undefined ? String(params.semester).trim() : null;
    var skills = params.skills !== undefined ? String(params.skills).trim() : null;

    var updatedInUsers = false;
    var usersSheet = spreadsheet.getSheetByName("Users");
    if (usersSheet) {
      var uData = usersSheet.getDataRange().getValues();
      if (uData.length > 1) {
        var uHeaders = uData[0].map(function (h) { return h.toString().trim().toLowerCase(); });

        var uIdCol = uHeaders.indexOf("user id");
        if (uIdCol === -1) uIdCol = uHeaders.indexOf("userid");
        if (uIdCol === -1) uIdCol = uHeaders.indexOf("student id");
        if (uIdCol === -1) uIdCol = 0;

        var nameCol = uHeaders.indexOf("name");
        if (nameCol === -1) nameCol = uHeaders.indexOf("fullname");
        if (nameCol === -1) nameCol = 1;

        var emailCol = uHeaders.indexOf("email");
        if (emailCol === -1) emailCol = uHeaders.indexOf("emailaddress");
        if (emailCol === -1) emailCol = 2;

        var mobileCol = uHeaders.indexOf("mobile");
        if (mobileCol === -1) mobileCol = uHeaders.indexOf("phone");
        if (mobileCol === -1) mobileCol = 3;

        var statusCol = uHeaders.indexOf("status");
        if (statusCol === -1) statusCol = uHeaders.indexOf("user status");
        if (statusCol === -1) statusCol = 5;

        for (var i = 1; i < uData.length; i++) {
          if (uData[i][uIdCol] && String(uData[i][uIdCol]).trim().toLowerCase() === userId.toLowerCase()) {
            if (name !== null) usersSheet.getRange(i + 1, nameCol + 1).setValue(name);
            if (email !== null) usersSheet.getRange(i + 1, emailCol + 1).setValue(email);
            if (mobile !== null) usersSheet.getRange(i + 1, mobileCol + 1).setValue(mobile);
            if (status !== null) usersSheet.getRange(i + 1, statusCol + 1).setValue(status);
            updatedInUsers = true;
            break;
          }
        }
      }
    }

    var updatedInProfiles = false;
    var profSheet = spreadsheet.getSheetByName("StudentProfiles");
    if (profSheet) {
      var pData = profSheet.getDataRange().getValues();
      if (pData.length > 1) {
        var pHeaders = pData[0].map(function (h) { return h.toString().trim().toLowerCase(); });
        var pIdCol = pHeaders.indexOf("user id");
        if (pIdCol === -1) pIdCol = pHeaders.indexOf("userid");
        if (pIdCol === -1) pIdCol = pHeaders.indexOf("student id");
        if (pIdCol === -1) pIdCol = 0;

        var pNameCol = pHeaders.indexOf("name");
        if (pNameCol === -1) pNameCol = pHeaders.indexOf("fullname");
        if (pNameCol === -1) pNameCol = 1;

        var pEmailCol = pHeaders.indexOf("email");
        if (pEmailCol === -1) pEmailCol = pHeaders.indexOf("emailaddress");
        if (pEmailCol === -1) pEmailCol = 2;

        var pMobileCol = pHeaders.indexOf("mobile");
        if (pMobileCol === -1) pMobileCol = pHeaders.indexOf("phone");
        if (pMobileCol === -1) pMobileCol = 3;

        var pEduCol = pHeaders.indexOf("education");
        if (pEduCol === -1) pEduCol = pHeaders.indexOf("course");
        if (pEduCol === -1) pEduCol = 4;

        var pSemCol = pHeaders.indexOf("semester");
        if (pSemCol === -1) pSemCol = pHeaders.indexOf("sem");
        if (pSemCol === -1) pSemCol = 5;

        var pSkillsCol = pHeaders.indexOf("skills");
        if (pSkillsCol === -1) pSkillsCol = pHeaders.indexOf("skill");
        if (pSkillsCol === -1) pSkillsCol = 6;

        for (var k = 1; k < pData.length; k++) {
          if (pData[k][pIdCol] && String(pData[k][pIdCol]).trim().toLowerCase() === userId.toLowerCase()) {
            if (name !== null) profSheet.getRange(k + 1, pNameCol + 1).setValue(name);
            if (email !== null) profSheet.getRange(k + 1, pEmailCol + 1).setValue(email);
            if (mobile !== null) profSheet.getRange(k + 1, pMobileCol + 1).setValue(mobile);
            if (education !== null && pEduCol !== -1) profSheet.getRange(k + 1, pEduCol + 1).setValue(education);
            if (semester !== null && pSemCol !== -1) profSheet.getRange(k + 1, pSemCol + 1).setValue(semester);
            if (skills !== null && pSkillsCol !== -1) profSheet.getRange(k + 1, pSkillsCol + 1).setValue(skills);
            updatedInProfiles = true;
            break;
          }
        }
      }
    }

    if (!updatedInUsers && !updatedInProfiles) {
      return jsonResponse({
        success: false,
        message: "Student record (" + userId + ") was not found."
      });
    }

    return jsonResponse({
      success: true,
      message: "Student record (" + userId + ") updated successfully."
    });

  } catch (error) {
    return jsonResponse({
      success: false,
      message: "Failed to update student: " + error.toString()
    });
  }
}
