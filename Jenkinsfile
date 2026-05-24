pipeline {
    agent { label 'worker'}

    
    tools {
        maven 'maven3'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-cred', url: 'https://github.com/jeevan-n-d/twitter.git'
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
                withSonarQubeEnv('sonar-qube') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                     -Dsonar.projectName=twitter-app \
                     -Dsonar.projectKey=twitter-app \
                     -Dsonar.java.binaries=target/classes \
                     -Dsonar.exclusions=target/**
                    '''
                }
            }
        }
      
      
      stage('Build') {
            steps {
                sh "mvn package -DskipTests"
            }
        }
      
      
      stage('Publish Artifacts') {
            steps {
                withMaven(
                    globalMavenSettingsConfig: 'maven-settings',
                    maven: 'maven3',
                    traceability: true
                ) {
                    sh "mvn deploy"
                }
            }
        }
      
       stage('Docker Build') {
            steps {
                sh "docker build -t jeeva08raj/twitter:release-3 ."
            }
        }
      
      
       stage('Trivy Image Scan') {
            steps {
                sh '''
                mkdir -p /home/ubuntu/trivy-tmp
                TMPDIR=/home/ubuntu/trivy-tmp \
                trivy image --format json -o trivy-image.json jeeva08raj/twitter:release-3
                '''
                }
            }
            
            
        stage('Docker Push') {
            steps {
                withDockerRegistry([ url: '', credentialsId: 'docker-cred-' ])  {
                    sh "docker push jeeva08raj/twitter:release-3"
                  }
            }
        }
      
        stage('K8-Deploy') {
            steps {
                withKubeConfig(
                    credentialsId: 'k8-cred',
                    namespace: 'webapps',
                    serverUrl: 'https://8.231.72.242'
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
                    serverUrl: 'https://8.231.72.242'
                ) {
                    sh "kubectl get pods -n webapps"
                    sh "kubectl get svc -n webapps"
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
                    to: "jeevanrajeshgowda@gmail.com",
                    from: "rockrollno121@gmail.com",
                    replyTo: "4ra22cs040@rithassan.ac.in",
                    mimeType: "text/html"
                )
            }
        }
    }
}
    
