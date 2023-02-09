properties([
  parameters([

    // Generic
    string(name: 'account', defaultValue: 'test', description: "message descriotion here..."),
    choice(name: 'ENVIRONMENT', choices: ['test', 'dev', 'prod'], description: "env name"),
    // desired nodes to be backup
        [$class: 'CascadeChoiceParameter',
      name: 'skip_jobs', choiceType: 'PT_CHECKBOX', description: 'Select jobs to be Skip.',
      filterLength: 1, filterable: false, referencedParameters: 'ENVIRONMENT',
      script: [$class: 'GroovyScript',
          script: [
              classpath: [],
              sandbox: true,
              script: """
                  if (ENVIRONMENT.equals('dev')){
                    return["\${ENVIRONMENT}-devjob", 'job2', 'job3']
                  } else if (ENVIRONMENT.equals('test')) {
                    return["\${ENVIRONMENT}-testjob", 'job2', 'job3']
                  } else {
                    return["other-job1", 'job2', 'job3']
                  }
              """.stripIndent()

          ]
      ]
    ]
  ])
])
