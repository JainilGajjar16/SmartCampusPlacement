/**
 * Smart Campus Placement - Apps Script Code.gs Additions (Phases 6, 7 & 8)
 * 
 * INSTRUCTIONS FOR GOOGLE APPS SCRIPT:
 * 1. Open your existing Google Spreadsheet.
 * 2. Go to Extensions > Apps Script to open Code.gs.
 * 3. In doGet(e), add action handling for Phase 8 & Company Module to your existing action check:
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
              cgpa: getProfVal(pRow, ["cgpa", "marks"])
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


