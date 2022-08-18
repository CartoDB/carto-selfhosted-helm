#!/bin/sh

#  CARTO 3 Self hosted dump kubernetes info
#
# Usage:
#   dump_carto_info.sh --n <namespace> --release <helm_release>
#

_bad_arguments() {
	echo "Missing or bad arguments"
	_print_help
	exit 1
}

_print_help() {
	cat <<-EOF
		usage: bash carto-dump.sh [-h] --namespace NAMESPACE --release HELM_RELEASE

		mandatory arguments:
			--namespace NAMESPACE                                                    e.g. carto
			--release   HELM_RELEASE                                                 e.g. carto

		optional arguments:
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
	"--*")
		_bad_arguments
		;;
	esac
done

# Check all mandatories args are passed by
if [ -z "${NAMESPACE}" ] ||
	[ -z "${HELM_RELEASE}" ]; then
	_bad_arguments
fi

_dump_info

}

_dump_info (){

DUMP_FOLDER="${HELM_RELEASE}-${NAMESPACE}_$(date "+%Y.%m.%d-%H.%M.%S")"
mkdir -p ${DUMP_FOLDER}/pod

echo "Downloading helm release info..."
helm list -n "${NAMESPACE}" > ${DUMP_FOLDER}/helm-release.out

echo "Downloading pods..."
kubectl get pods -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/pods.out 2>/dev/null
kubectl describe pods -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/pods.out 2>/dev/null
for POD in $(kubectl get pods -n "${NAMESPACE}" -o name -l app.kubernetes.io/instance="${HELM_RELEASE}"); \
  do kubectl logs ${POD} -n "${NAMESPACE}" > ${DUMP_FOLDER}/${POD}.log; done 2>/dev/null

echo "Downloading services..."
kubectl get svc -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/services.out 2>/dev/null
kubectl describe svc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/services.out 2>/dev/null

echo "Downloading endpoints..."
kubectl get endpoints -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/endpoints.out 2>/dev/null
kubectl describe endpoints -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/endpoints.out 2>/dev/null

echo "Downloading deployments..."
kubectl get deployments -n "${NAMESPACE}" -o wide -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/deployments.out 2>/dev/null
kubectl describe deployments -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/deployments.out 2>/dev/null

echo "Downloading ingress..."
kubectl get ingress -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/ingress.out 2>/dev/null
kubectl describe ingress -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/ingress.out 2>/dev/null

echo "Downloading BackendConfigs..."
kubectl get backendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/backendconfigs.out 2>/dev/null
kubectl describe backendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/backendconfigs.out 2>/dev/null

echo "Downloading FrontEndConfig..."
kubectl get frontendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/frontendconfigs.out 2>/dev/null
kubectl describe frontendconfigs -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/frontendconfigs.out 2>/dev/null

echo "Downloading events..."
kubectl get event -n "${NAMESPACE}" > ${DUMP_FOLDER}/events.out 2>/dev/null

echo "Downloading pvc..."
kubectl get pvc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/pvc.out 2>/dev/null
kubectl describe pvc -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/pvc.out 2>/dev/null

echo "Downloading secrets info without passwords..."
kubectl get secrets -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" > ${DUMP_FOLDER}/secrets.out 2>/dev/null
kubectl describe secrets -n "${NAMESPACE}" -l app.kubernetes.io/instance="${HELM_RELEASE}" >> ${DUMP_FOLDER}/secrets.out 2>/dev/null

echo "Creating tar file..."
tar -czvf ${DUMP_FOLDER}.tar.gz ${DUMP_FOLDER} 2>/dev/null

}

_main "$@"
