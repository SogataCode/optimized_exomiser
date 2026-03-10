#!/bin/bash
CSV_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_YML="${SCRIPT_DIR}/optimized_template.yml"


while IFS=, read -r sample vcf_path ped_path proband_id hpos; do
    echo "[INFO] ###Processing sample: ${sample}###"
    if [ ! -e "${vcf_path}" ]; then
        echo "[ERROR] no file found for sample:${sample}"
        continue
    fi

    OUT_DIR=$(dirname "${vcf_path}")/${sample}_exomiser
    mkdir -p "${OUT_DIR}"
    OUT_VCF="${OUT_DIR}/${sample}_QC.vcf.gz"

    if [ -n "${ped_path}" ]; then
        if [ ! -e "${ped_path}" ]; then
        echo "[ERROR] no ped file found for sample:${sample}, skipping."
        continue
        fi
        echo "[INFO] This analysis use pedigree information from ${ped_path}"
        ID_LIST=$(bcftools query -l ${vcf_path})
        if printf "%s\n" "${ID_LIST}" | grep -Fxq "${proband_id}"; then
            echo "[INFO] Specified Proband ID found in VCF: ${proband_id}"
            SAMPLE_ID="${proband_id}"
        else
            echo "[ERROR] Specified Proband ID not found in VCF."
            echo "[ERROR] ID list in VCF:"
            echo "${ID_LIST}"
            echo "[ERROR] Skipping."
            continue
        fi
    else
        echo "[INFO] This analysis is proband-only mode."
        ID_LIST=$(bcftools query -l ${vcf_path})
        ID_NUM=$(printf "%s\n" "${ID_LIST}" | sed '/^$/d' | wc -l)
        if [ "${ID_NUM}" -eq 1 ]; then
            echo "[INFO] VCF contains a single sample, proceeding in proband-only mode."
            SAMPLE_ID="${ID_LIST}"
        else
            # multiple samples
            if [ -z "${proband_id}" ]; then
                echo "[ERROR] VCF contains ${ID_NUM} samples, but no proband_id was specified."
                echo "[ERROR] VCF samples:"
                echo "${ID_LIST}"
                echo "[ERROR] Specify the proband ID in the CSV (proband_id column) or use a single-sample VCF."
                echo "[ERROR] Skipping."
                continue
            else
                if printf "%s\n" "${ID_LIST}" | grep -Fxq "${proband_id}"; then
                    echo "[INFO] Specified proband ID found in VCF: ${proband_id}"
                    SAMPLE_ID="${proband_id}"
                    bcftools view -s "${SAMPLE_ID}" -O z -o "${OUT_DIR}/${sample}_singleton.vcf.gz" "${vcf_path}"
                    bcftools index -t "${OUT_DIR}/${sample}_singleton.vcf.gz"
                    vcf_path="${OUT_DIR}/${sample}_singleton.vcf.gz"
                    OUT_VCF="${OUT_DIR}/${sample}_singleton_QC.vcf.gz"
                    echo "[INFO] Proband-only VCF file is created for sample: ${SAMPLE_ID}"
                else
                    echo "[ERROR] Proband ID specified in CSV but not found in VCF."
                    echo "[ERROR] Proband ID: ${proband_id}"
                    echo "[ERROR] VCF samples:"
                    echo "${ID_LIST}"
                    echo "[ERROR] Skipping"
                    continue
                fi
            fi
        fi
    fi
    echo ${SAMPLE_ID} > "${OUT_DIR}/proband_id.txt"
    FILTER_EXPR='FORMAT/GQ[@'"${OUT_DIR}"/proband_id.txt'] < 20 || ( GT[@'"${OUT_DIR}"/proband_id.txt'] = "het" && ( FORMAT/VAF[@'"${OUT_DIR}"/proband_id.txt'] < 0.15 || FORMAT/VAF[@'"${OUT_DIR}"/proband_id.txt'] > 0.85 ) ) || ALT="*"'
    bcftools +fill-tags -O u "${vcf_path}" -- -t FORMAT/VAF,HWE \
    | bcftools view -O z -o "${OUT_VCF}" -e "${FILTER_EXPR}"

    #bcftools +fill-tags -O u ${vcf_path} -- -t FORMAT/VAF,HWE | bcftools view -O z -o ${OUT_VCF} -e "FORMAT/GQ[@${SAMPLE_LIST}] < 20 || ( GT[@${SAMPLE_LIST}]="het" && ( FORMAT/VAF[@${SAMPLE_LIST}] < 0.15 || FORMAT/VAF[@${SAMPLE_LIST}] > 0.85  ) ) || ALT ="*""
    bcftools index -t ${OUT_VCF}
    echo "[INFO] VCF filtering(GQ<20, hetero_VAF 15~85%) is completed. Writed to ${OUT_VCF}"
    
    FORMATTED_HPO=$(echo "${hpos}" | tr ',' '\n' | awk '{if($1!="")printf "'\''%s'\''", $1; if(NR>0 && $1!="") printf ","}' | sed 's/,$//')
    OUT_YML="${OUT_DIR}/${sample}-config.yml"
    OUT_NAME=$(basename "${OUT_VCF}" .vcf.gz)
    sed \
        -e 's|VCF_PATH|'"${OUT_VCF}"'|g' \
        -e 's|PED_PATH|'"${ped_path}"'|g' \
        -e 's|PROBAND_ID|'"${proband_id}"'|g' \
        -e 's|HPO_ID|'"$FORMATTED_HPO"'|g' \
        -e 's|OUT_DIR|'"${OUT_DIR}"'|g' \
        -e 's|OUT_NAME|'"${OUT_NAME}"'|g' \
        -e 's|"||g'\
        "$TEMP_YML" > "$OUT_YML"
    echo "[INFO] Analysis based on $OUT_YML"
    cd "${SCRIPT_DIR}" || exit 1
    java -Xmx64g \
    -Dspring.config.location=./application.properties \
    -jar ./exomiser-cli-14.1.0.jar \
    --analysis "$OUT_YML"

    #source python_venv.sh
    python ${SCRIPT_DIR}/postfilter.py ${OUT_DIR}/${OUT_NAME}_exomiser.variants.tsv
    echo "[INFO] Successfully finished sample: ${sample}"
done < <(tail -n +2  "$CSV_FILE" | tr -d '\r')
echo "[INFO] All samples are processed."
