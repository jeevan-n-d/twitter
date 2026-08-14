pipeline {
    agent none

    tools {
        maven 'maven'
        jdk 'jdk17'
    }

    environment {
        GIT_URL = 'https://github.com/jeevan-n-d/twitter.git'
        GIT_BRANCH = 'main'

        PROJECT_KEY = 'twitter-app'
        PROJECT_NAME = 'twitter-app'

        DOCKERHUB_REPO = 'jeeva08raj/twitter'
        IMAGE_TAG = "${BUILD_NUMBER}"

        TRIVY_IMAGE = 'aquasec/trivy:0.72.0'
        IMG_REPORT = 'trivy-image.html'

        APP_NAMESPACE = 'webapps'

        ZAP_REPORT_PATH = 'Zap-Report.html'
        TARGET_URL = 'http://a34df0a3239464d4d8816dae857d3663-2001816633.ap-south-2.elb.amazonaws.com/'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Master Node') {

            agent {
                label 'master'
            }

            stages {

                stage('Checkout') {
                    steps {
                        git(
                            branch: "${GIT_BRANCH}",
                            url: "${GIT_URL}"
                        )
                    }
                }

                stage('Compile') {
                    steps {
                        sh 'mvn clean compile'
                    }
                }

                stage('Test') {
                    steps {
                        sh 'mvn test'
                    }
                }

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

                stage('Build Application') {
                    steps {
                        sh 'mvn package -DskipTests'
                    }
                }

                stage('Publish Artifacts') {
                    steps {

                        withMaven(
                            globalMavenSettingsConfig: 'maven-settings',
                            maven: 'maven',
                            jdk: 'jdk17',
                            traceability: true
                        ) {

                            sh 'mvn deploy'
                        }
                    }
                }

                stage('Prepare Worker Workspace') {
                    steps {

                        stash(
                            name: 'application',
                            includes: '**/*',
                            excludes: '.git/**',
                            useDefaultExcludes: false
                        )

                        echo "Application workspace transferred to worker"
                    }
                }
            }
        }


        stage('Worker Node') {

            agent {
                label 'worker'
            }

            stages {

                stage('Restore Workspace') {
                    steps {

                        deleteDir()

                        unstash 'application'

                        echo "Workspace restored on worker"
                    }
                }

                stage('Build Docker Image') {
                    steps {

                        sh """
                            docker build \
                              -t ${DOCKERHUB_REPO}:${IMAGE_TAG} .
                        """
                    }
                }


                stage('Trivy Image Scan') {
                    steps {

                        sh """
                            docker run --rm \
                              -v /var/run/docker.sock:/var/run/docker.sock \
                              -v \$(pwd):/workspace \
                              ${TRIVY_IMAGE} image \
                              --timeout 30m \
                              --format template \
                              --template "@/contrib/html.tpl" \
                              -o /workspace/${IMG_REPORT} \
                              ${DOCKERHUB_REPO}:${IMAGE_TAG}
                        """
                    }
                }


                // ====================================================
                // TRIVY FILESYSTEM SCAN
                // ====================================================

                stage('Trivy FS Scan') {
                    steps {

                        sh '''
                            docker run --rm \
                              -v /home/ubuntu/jenkins/workspace/twitter:/workspace \
                              -v /home/ubuntu/.m2:/root/.m2:ro \
                              aquasec/trivy:0.72.0 \
                              fs \
                              --format json \
                              -o /workspace/trivy-fs-report.json \
                              /workspace
                        '''
                    }
                }


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
                                echo "\$DOCKER_PASS" | \
                                docker login \
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


                stage('Deploy App (K8s)') {
                    steps {

                        sh """
                            set -e

                            export KUBECONFIG=/home/ubuntu/.kube/config

                            kubectl config current-context

                            kubectl get nodes

                            kubectl get namespace ${APP_NAMESPACE} || kubectl create namespace ${APP_NAMESPACE}

                            ls -l deployment-service.yml

                            kubectl apply \
                              -f deployment-service.yml \
                              -n ${APP_NAMESPACE}

                            kubectl set image \
                              deployment/bloggingapp-deployment \
                              bloggingapp=${DOCKERHUB_REPO}:${IMAGE_TAG} \
                              -n ${APP_NAMESPACE}

                            kubectl rollout status \
                              deployment/bloggingapp-deployment \
                              -n ${APP_NAMESPACE} \
                              --timeout=180s
                        """
                    }
                }


                stage('Verify Deployment') {
                    steps {

                        sh """
                            set -e

                            export KUBECONFIG=/home/ubuntu/.kube/config

                            kubectl get deployment \
                              bloggingapp-deployment \
                              -n ${APP_NAMESPACE}

                            kubectl get pods \
                              -n ${APP_NAMESPACE} \
                              -o wide

                            kubectl get svc \
                              -n ${APP_NAMESPACE}

                            kubectl get deployment \
                              bloggingapp-deployment \
                              -n ${APP_NAMESPACE} \
                              -o jsonpath='{.spec.template.spec.containers[0].image}'

                            echo ""
                        """
                    }
                }


                stage('OWASP ZAP Scan') {
                    steps {

                        sh """
                            docker run --rm \
                              -u 0 \
                              -v \$(pwd):/zap/wrk/:rw \
                              ghcr.io/zaproxy/zaproxy:stable \
                              zap-full-scan.py \
                              -t ${TARGET_URL} \
                              -g gen.conf \
                              -r ${ZAP_REPORT_PATH} || true
                        """
                    }
                }
            }
        }
    }


    // ====================================================
    // POST ACTIONS
    // ONLY FIXED NODE CONTEXT HERE
    // ====================================================

    post {

        success {
            echo "Twitter DevSecOps pipeline completed successfully"
        }


        failure {
            echo "Twitter DevSecOps pipeline failed"
        }


        always {

            node('worker') {

                script {

                    if (fileExists("trivy-fs-report.json")) {

                        echo "Trivy filesystem report generated"

                    } else {

                        echo "Trivy filesystem report not found"
                    }


                    if (fileExists("${IMG_REPORT}")) {

                        echo "Trivy image report generated"

                    } else {

                        echo "Trivy image report not found"
                    }


                    if (fileExists("${ZAP_REPORT_PATH}")) {

                        echo "ZAP report generated"

                    } else {

                        echo "ZAP report not found"
                    }
                }


                archiveArtifacts(
                    artifacts: 'trivy-fs-report.json,trivy-image.html,Zap-Report.html',
                    allowEmptyArchive: true
                )


                sh 'docker logout || true'
            }
        }
    }
}