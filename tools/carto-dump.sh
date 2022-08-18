#!/bin/sh

#  CARTO 3 Self hosted dump kubernetes info
#
# Usage:
#   dump_carto_info.sh --n <namespace> --release <helm_release> --engine <engine> [--extra]
#

_bad_arguments() {
	echo "Missing or bad arguments"
	_print_help
	exit 1
}

_print_help() {
	cat <<-EOF
		usage: bash carto-dump.sh [-h] --namespace NAMESPACE --release HELM_RELEASE --engine ENGINE [--gcp-project] [--extra] 

		mandatory arguments:
			--namespace NAMESPACE                                                    e.g. carto
			--release   HELM_RELEASE                                                 e.g. carto
			--engine    ENGINE                                                       specify your kubernetes cluster engine, e.g. gke, aks, eks or custom

		optional arguments:
			--extra                                                                  download all cluster info, this option need to run containers in your kubernetes cluster to obtain extra checks
			--gcp-project                                                            in case of GKE engine, specify your GCP project in which Kubernetes is deployed
			-h, --help                                                               show this help message and exit
	EOF
}

_main() {
	ARGS=("$@")

	for index in "${!ARGS[@]}"; do
		case "${ARGS[index]}" in
		"--namespace")
			NAMESPACE="${ARGS[index + 1]}"
			;;
		"--release")
			HELM_RELEASE="${ARGS[index + 1]}"
			;;
		"--engine")
			ENGINE="${ARGS[index + 1]}"
			;;
		"--gcp-project")
		    GCP_PROJECT="${ARGS[index + 1]}"
			;;
		"--extra")
		    EXTRA_CHECKS="true"
			;;
		"--*")
			_bad_arguments
			;;
		esac
	done

	# Check all mandatories args are passed by
	if [ -z "${NAMESPACE}" ] ||
		[ -z "${HELM_RELEASE}" ] ||
		[ -z "${ENGINE}" ]; then
		_bad_arguments
	fi

	_dump_info

	if [ "${EXTRA_CHECKS}" == "true" ]; then
	  _dump_extra_checks
	fi

	if [ "${ENGINE}" == "gke" ] && [ "${GCP_PROJECT}" != "" ]; then
	  _check_gke
	fi

	echo "Creating tar file..."
	tar -czvf "${DUMP_FOLDER}".tar.gz "${DUMP_FOLDER}" 2>>"${DUMP_FOLDER}"/error.log
}

_dump_info (){
	DUMP_FOLDER="${HELM_RELEASE}-${NAMESPACE}_$(date "+%Y.%m.%d-%H.%M.%S")"
	mkdir -p "${DUMP_FOLDER}"/pod

	echo "Downloading helm release info..."
	helm list -n "${NAMESPACE}" > "${DUMP_FOLDER}"/helm_release.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading pods..."
	kubectl get pods -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/pods.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe pods -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/pods.out 2>>"${DUMP_FOLDER}"/error.log
	for POD in $(kubectl get pods -n "${NAMESPACE}" -o name -l app.kubernetes.io/instance="${HELM_RELEASE}"); \
	  do kubectl logs ${POD} -n "${NAMESPACE}" > "${DUMP_FOLDER}"/"${POD}".log 2>>"${DUMP_FOLDER}"/error.log; done 

	echo "Downloading services..."
	kubectl get svc -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/services.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe svc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/services.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading endpoints..."
	kubectl get endpoints -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/endpoints.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe endpoints -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/endpoints.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading deployments..."
	kubectl get deployments -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/deployments.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe deployments -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/deployments.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading ingress..."
	kubectl get ingress -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/ingress.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe ingress -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/ingress.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading BackendConfigs..."
	kubectl get backendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/backendconfigs.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe backendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/backendconfigs.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading FrontEndConfig..."
	kubectl get frontendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/frontendconfigs.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe frontendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/frontendconfigs.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading events..."
	kubectl get event -n "${NAMESPACE}" > "${DUMP_FOLDER}"/events.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading pvc..."
	kubectl get pvc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/pvc.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe pvc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/pvc.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Downloading secrets info without passwords..."
	kubectl get secrets -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > "${DUMP_FOLDER}"/secrets.out 2>>"${DUMP_FOLDER}"/error.log
	kubectl describe secrets -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> "${DUMP_FOLDER}"/secrets.out 2>>"${DUMP_FOLDER}"/error.log
}

_dump_extra_checks () {
	echo "Downloading cluster info..."
	kubectl cluster-info dump --namespaces="${NAMESPACE}" > "${DUMP_FOLDER}"/cluster_info.out 2>>"${DUMP_FOLDER}"/error.log

	echo "Checking Api health..."
	echo "Checking Workspace API -> " >> "${DUMP_FOLDER}"/health_checks.out
	kubectl run "${HELM_RELEASE}"-healthcheck --image=curlimages/curl -n "${NAMESPACE}" --rm -i --tty --restart='Never' \
	  -- curl http://carto-workspace-api >> "${DUMP_FOLDER}"/health_checks.out 2>>"${DUMP_FOLDER}"/error.log
	echo "Checking Maps API -> " >> "${DUMP_FOLDER}"/health_checks.out
	kubectl run "${HELM_RELEASE}"-healthcheck --image=curlimages/curl -n "${NAMESPACE}" --rm -i --tty --restart='Never' \
	  -- curl http://carto-maps-api >> "${DUMP_FOLDER}"/health_checks.out 2>>"${DUMP_FOLDER}"/error.log
	echo "Checking Import API -> " >> "${DUMP_FOLDER}"/health_checks.out
	kubectl run "${HELM_RELEASE}"-healthcheck --image=curlimages/curl -n "${NAMESPACE}" --rm -i --tty --restart='Never' \
	  -- curl http://carto-import-api >> "${DUMP_FOLDER}"/health_checks.out 2>>"${DUMP_FOLDER}"/error.log
}

_check_gke () {
	echo "Check Ingress cert..."
	SSL_CERT_ID=$(kubectl get ingress "${HELM_RELEASE}"-router -n "${NAMESPACE}" \
	  -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/ssl-cert}' 2>>"${DUMP_FOLDER}"/error.log)
    gcloud --project "${GCP_PROJECT}" compute ssl-certificates describe "${SSL_CERT_ID}" >> "${DUMP_FOLDER}"/ingress-ssl-cert.out 2>>"${DUMP_FOLDER}"/error.log
}

_main "$@"
