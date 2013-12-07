TODO
====

- browser crash
- proxy crash
- skip over bad activities
  - which one is bad?
    - which one has been tried and failed multiple times?
      - or how long has it been the current activity?
      - and how long has it been since a credit?
    - which one is it currently on?
- Current
  - show current activity
    - thumbnail
    - SB amount
    - UserOps
    - Number of attempts
    - Number of SB increments since first running activity
    - Last Run
  - show list of coming up activities
- Blacklist
  - List
  - Add
  - Remove
- System Admin
  - show uptime / last restart
  - force restart
- remote ssh access

# encrave-runner

    CHECK_SYSTEM_COMMAND_INTERVAL = 60*1000*5
    LAUNCH_TIMEOUT = 5*1000

    checkAndLaunchSystemCommands = ->
      url = "https://api.mongolab.com/api/1/databases/consigliere/collections/system-commands"
      url += "?s=#{JSON.stringify issueTime: -1}&l=1"
      https.get(url,(res)->
        res.on 'data', (data)->
          data = JSON.parse data.toString()

          # Execute command, otherwise ignore
          unless data.resultTime
            if data.command is "restart"
              launchProxy()
              setTimeout (->
                launchBrowser()

                # Post response
                setTimeout (->
                  req = https.request
                    host: 'api.mongolab.com'
                    method: 'POST'
                    path: "/api/1/databases/consigliere/collections/system-commands/#{data._id}"
                    headers:
                      'Content-Type': 'application/json'
                  req.end JSON.stringify
                    resultTime: Date.now()
                    result: "done"
                ), LAUNCH_TIMEOUT
              ), LAUNCH_TIMEOUT
        ).on 'error', (e)-> console.log "error", e

    setInterval checkAndLaunchSystemCommands, CHECK_SYSTEM_COMMAND_INTERVAL

# encrave

    # YYYY-MM-DD
    getTodayDateString = -> new Date().toISOString().substring(0,10)

    $http(method:'GET', url:"https://api.mongolab.com/api/1/databases/consigliere/collections/activities?apiKey=4cIC7N8HM4TTAeOHVNrR3CstB1eGJQ7z&q=#{JSON.stringify date: getTodayDateString()}")
      .then (data)->
        # TODO: First run of the day
        unless data
          # TODO: Create array of documents
          # POST https://api.mongolab.com/api/1/databases/consigliere/collections/activities?apiKey=4cIC7N8HM4TTAeOHVNrR3CstB1eGJQ7z

        # Update current activity data
        else
          # Update current activity data
          # - Look up current placement
          # - $set
          #   - ops: Placement.UserOps
          #   - lastRun: Date.now()
          # - $inc
          #   - attempts: 1


# consigliere

    # current-activities.coffee

    controller: ($scope)->
      # YYYY-MM-DD
      getTodayDateString = -> new Date().toISOString().substring(0,10)

      Activity = new Resource
        url: "https://api.mongolab.com/api/1/databases/consigliere/collections/activities/:id"
        params:
          apiKey: "4cIC7N8HM4TTAeOHVNrR3CstB1eGJQ7z"

      Activity
        .query(date: getTodayDateString())
        .then (data)->
          # if no data for today
          if not data
            $scope.noDataForToday = true

          else
            # Get current activity
            $scope.currentActivity = data.splice(0,1)

            # Other activities
            $scope.activities = data


# API spec

## /api/activities

    activity : {
      date
      id
      imgUrl
      description
      ops
      lastRun
      attempts
      sbIncrements
      blacklisted
    }

## /api/system-commands

    command : {
      issueTime
      resultTime
      command (restart)
      result
    }
