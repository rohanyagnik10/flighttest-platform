pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
    - name: terraform
      image: hashicorp/terraform:1.9.8
      command: ["sleep"]
      args: ["infinity"]
'''
        }
    }

    parameters {
        choice(name: 'ENV', choices: ['uat', 'preprod', 'prod'])
    }

    stages {
        stage('Init') {
            steps {
                container('terraform') {
                    dir("environments/${params.ENV}") {
                        sh 'terraform init -input=false'
                    }
                }
            }
        }

        stage('Validate') {
            steps {
                container('terraform') {
                    dir("environments/${params.ENV}") {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Plan') {
            steps {
                container('terraform') {
                    dir("environments/${params.ENV}") {
                        sh 'terraform plan -input=false -out=tfplan'
                    }
                }
            }
        }

        stage('Approve') {
            steps {
                input message: "Apply to ${params.ENV}?"
            }
        }

        stage('Apply') {
            steps {
                container('terraform') {
                    dir("environments/${params.ENV}") {
                        sh 'terraform apply -input=false tfplan'
                    }
                }
            }
        }
    }
}
