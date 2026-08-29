pipeline {

    agent none

    tools {
        maven 'maven'
        jdk 'jdk17'
    }

    environment {

        REPO_URL = 'https://github.com/jeevan-n-d/twitter.git'
        REPO_BRANCH = 'prod'

        PROJECT_KEY = 'twitter-app'
        PROJECT_NAME = 'twitter-app'

        DOCKERHUB_REPO = 'jeeva08raj/twitter'
        IMAGE_TAG = "${BUILD_NUMBER}"

        TRIVY_IMAGE = 'aquasec/trivy:0.72.0'
        IMG_REPORT = 'trivy-image.html'

        APP_NAMESPACE = 'webapps'

        ZAP_REPORT_PATH = 'Zap-Report.html'
        TARGET_URL = 'https://twitter.mycoolprojects.online'
    }

    stages {

        // ============================================================
        // MASTER NODE
        // ============================================================

        stage('Master Node') {

            agent {
                label 'master'
            }

            stages {

                // ----------------------------------------------------
                // CHECKOUT
                // ----------------------------------------------------

                stage('Checkout') {
                    steps {
                        git(
                            branch: "${REPO_BRANCH}",
                            url: "${REPO_URL}"
                        )
                    }
                }

                // ----------------------------------------------------
                // COMPILE
                // ----------------------------------------------------

                stage('Compile') {
                    steps {
                        sh 'mvn clean compile'
                    }
                }

                // ----------------------------------------------------
                // BUILD APPLICATION
                // ----------------------------------------------------

                stage('Build Application') {
                    steps {
                        sh 'mvn package'
                    }
                }

                // ----------------------------------------------------
                // SONARQUBE ANALYSIS
                // ----------------------------------------------------

                stage('SonarQube Analysis') {
                    steps {
                        script {

                            withSonarQubeEnv('sonar-server') {

                                def scannerHome = tool 'sonar-scanner'

                                sh """
                                    ${scannerHome}/bin/sonar-scanner \
                                      -Dsonar.projectKey=${PROJECT_KEY} \
                                      -Dsonar.projectName="${PROJECT_NAME}" \
                                      -Dsonar.sources=. \
                                      -Dsonar.java.binaries=target/classes \
                                      -Dsonar.exclusions=target/**
                                """
                            }
                        }
                    }
                }

                // ----------------------------------------------------
                // TRIVY FILESYSTEM SCAN
                // ----------------------------------------------------

                stage('Trivy FS Scan') {
                    steps {

                        sh """
                            docker run --rm \
                              -v \$(pwd):/workspace \
                              ${TRIVY_IMAGE} \
                              fs \
                              --format template \
                              --template="@/contrib/html.tpl" \
                              -o /workspace/trivy-fs-report.html \
                              /workspace
                        """

                        archiveArtifacts(
                            artifacts: 'trivy-fs-report.html'
                        )
                    }
                }

                // ----------------------------------------------------
                // PUBLISH JAR TO NEXUS
                // ----------------------------------------------------

                stage('Publish Artifacts') {
                    steps {

                        withMaven(
                            globalMavenSettingsConfig: 'maven-settings',
                            maven: 'maven',
                            jdk: 'jdk17'
                        ) {

                            sh 'mvn deploy'
                        }
                    }
                }
            }
        }

        // ============================================================
        // WORKER NODE
        // ============================================================

        stage('Worker Node') {

            agent {
                label 'worker'
            }

            stages {

                // ----------------------------------------------------
                // CHECKOUT
                // ----------------------------------------------------

                stage('Checkout') {
                    steps {

                        git(
                            branch: "${REPO_BRANCH}",
                            url: "${REPO_URL}"
                        )
                    }
                }

                // ----------------------------------------------------
                // DOWNLOAD JAR FROM NEXUS
                // ----------------------------------------------------

                stage('Download JAR from Nexus') {
                    steps {

                        withMaven(
                            globalMavenSettingsConfig: 'maven-settings',
                            maven: 'maven',
                            jdk: 'jdk17'
                        ) {

                            sh '''
                                mkdir -p target

                                mvn dependency:get \
                                  -Dartifact=com.example:twitter-app:1.0.1-SNAPSHOT:jar \
                                  -Dtransitive=false \
                                  -DremoteRepositories=maven-snapshots::default::http://18.60.255.40:8081/repository/maven-snapshots/ \
                                  -Ddest=target/app.jar
                            '''
                        }
                    }
                }

                // ----------------------------------------------------
                // BUILD DOCKER IMAGE
                // ----------------------------------------------------

                stage('Build Docker Image') {
                    steps {

                        sh """
                            docker build \
                              -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                        """
                    }
                }

                // ----------------------------------------------------
                // TRIVY DOCKER IMAGE SCAN
                // ----------------------------------------------------

                stage('Trivy Image Scan') {
                    steps {

                        sh """
                            docker run --rm \
                              -v /var/run/docker.sock:/var/run/docker.sock \
                              -v \$(pwd):/workspace \
                              ${TRIVY_IMAGE} \
                              image \
                              --format template \
                              --template="@/contrib/html.tpl" \
                              -o /workspace/${IMG_REPORT} \
                              ${DOCKERHUB_REPO}:${IMAGE_TAG}
                        """

                        archiveArtifacts(
                            artifacts: "${IMG_REPORT}"
                        )
                    }
                }

                // ----------------------------------------------------
                // DOCKER LOGIN & PUSH
                // ----------------------------------------------------

                stage('Docker Login & Push') {
                    steps {

                        withCredentials([
                            usernamePassword(
                                credentialsId: 'dock-creds',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )
                        ]) {

                            sh """
                                echo "\$DOCKER_PASS" | docker login \
                                  -u "\$DOCKER_USER" \
                                  --password-stdin

                                docker push \
                                  ${DOCKERHUB_REPO}:${IMAGE_TAG}

                                docker tag \
                                  ${DOCKERHUB_REPO}:${IMAGE_TAG} \
                                  ${DOCKERHUB_REPO}:latest

                                docker push \
                                  ${DOCKERHUB_REPO}:latest
                            """
                        }
                    }
                }

                // ----------------------------------------------------
                // DEPLOY TO KUBERNETES
                // ----------------------------------------------------

                stage('Deploy App (K8s)') {
                    steps {

                        sh """
                            kubectl get nodes

                            kubectl create namespace ${APP_NAMESPACE} || true

                            kubectl get namespace ${APP_NAMESPACE}

                            ls -l deployment-service.yml

                            kubectl apply \
                              -f deployment-service.yml \
                              -n ${APP_NAMESPACE}
                        """
                    }
                }

                // ----------------------------------------------------
                // VERIFY KUBERNETES DEPLOYMENT
                // ----------------------------------------------------

                stage('Verify Deployment') {
                    steps {

                        sh """
                            kubectl get deployment \
                              bloggingapp-deployment \
                              -n ${APP_NAMESPACE}

                            kubectl get pods \
                              -n ${APP_NAMESPACE} \
                              -o wide

                            kubectl get svc \
                              -n ${APP_NAMESPACE}
                        """
                    }
                }

                // ----------------------------------------------------
                // OWASP ZAP DAST SCAN
                // ----------------------------------------------------

                stage('OWASP ZAP Scan') {
                    steps {

                        sh """
                            docker run --rm \
                              -u 0 \
                              -v \$(pwd):/zap/wrk/:rw \
                              ghcr.io/zaproxy/zaproxy:stable \
                              zap-full-scan.py \
                              -t ${TARGET_URL} \
                              -r ${ZAP_REPORT_PATH} || true
                        """

                        archiveArtifacts(
                            artifacts: "${ZAP_REPORT_PATH}"
                        )
                    }
                }
            }
        }
    }

    // ================================================================
    // POST ACTIONS
    // ================================================================

    post {

        success {

            echo "Twitter DevSecOps pipeline completed successfully"

            mail(
                to: 'jeevanrajeshgowda@gmail.com',

                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",

                body: """
Twitter DevSecOps Pipeline Completed Successfully

Job: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: SUCCESS

Build URL:
${env.BUILD_URL}
"""
            )
        }

        failure {

            echo "Twitter DevSecOps pipeline failed"

            mail(
                to: 'jeevanrajeshgowda@gmail.com',

                subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",

                body: """
Twitter DevSecOps Pipeline Failed

Job: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: FAILURE

Please check the Jenkins console output.

Build URL:
${env.BUILD_URL}
"""
            )
        }
    }
}