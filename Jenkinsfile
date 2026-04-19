pipeline {
    agent any
    
    tools {
        jdk 'jdk17'
        maven 'maven3'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    changelog: false,
                    credentialsId: 'github',
                    poll: false,
                    url: 'https://github.com/jeevan-n-d/blog-app.git'
            }
        }
        
        stage('Compile') {
            steps {
                sh "mvn clean compile"
            }
        }
        
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh "trivy fs --format json -o trivy-report.json ."
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=twitter-app \
                    -Dsonar.projectKey=twitter-app \
                    -Dsonar.java.binaries=target
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                sh "mvn package"
            }
        }
        
        stage('Publish Artifacts') {
            steps {
                withMaven(
                    globalMavenSettingsConfig: 'maven-settings',
                    jdk: 'jdk17',
                    maven: 'maven3',
                    traceability: true
                ) {
                    sh "mvn deploy"
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t jeeva08raj/twitterapp:latest ."
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'doc-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image --format json -o trivy-image.json jeeva08raj/twitterapp:latest"
            }
        }

        stage('Docker Push') {
            steps {
                sh "docker push jeeva08raj/twitterapp:latest"
            }
        }
        
        stage('K8-Deploy') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-cred',
                    namespace: 'webapps',
                    serverUrl: 'https://B8C878566F13A92C937D1369FFB1896D.gr7.eu-west-3.eks.amazonaws.com'
                ) {
                    sh "kubectl apply -f deployment-service.yml"
                    sleep 20
                }
            }
        }
        
        stage('Verify Deploy') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-cred',
                    namespace: 'webapps',
                    serverUrl: 'https://B8C878566F13A92C937D1369FFB1896D.gr7.eu-west-3.eks.amazonaws.com'
                ) {
                    sh "kubectl get pods"
                    sh "kubectl get svc"
                }
            }
        }
    }

    
    post {
        always {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                def pipelineStatus = currentBuild.currentResult
                def bannerColor = (pipelineStatus == "SUCCESS") ? "green" : "red"

                def body = """
                <html>
                <body>
                    <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                        <h2>${jobName} - Build ${buildNumber}</h2>
                        <div style="background-color: ${bannerColor}; padding: 10px;">
                            <h3 style="color: white;">Pipeline Status: ${pipelineStatus}</h3>
                        </div>
                        <p>Check the <a href="${env.BUILD_URL}">console output</a></p>
                    </div>
                </body>
                </html>
                """

                emailext(
                    subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus}",
                    body: body,
                    to: "rockrollno121@gmail.com",
                    from: "rockrollno121@gmail.com",
                    replyTo: "rockrollno121@gmail.com",
                    mimeType: "text/html"
                )
            }
        }
    }
}
