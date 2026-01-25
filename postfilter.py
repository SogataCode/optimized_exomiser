import pandas as pd
import argparse 
from pathlib import Path

def main():
    p = argparse.ArgumentParser(description="Post-filter Exomiser results based on custom criteria.")
    p.add_argument("input_file", help="Path to the Exomiser variants TSV file.")
    args = p.parse_args()
    df = pd.read_csv(args.input_file, sep="\t")
    
    gene_list = ['MUC4', 'GJC2', 'TDG', 'NFIA', 'SREBF1', 'TTN', 'MYH6', 'AP3S1', 'ATAT1', 'HLA-DRB1', 'PRKRA', 'ANAPC1', 'MRPL4', 'ASXL3', 'PRPF40B', 'TYRO3', 'TRA2A', 'VPS13B', 'SKA3', 'CCDC124', 'WIPF3', 'BICRA', 'MED13L', 'ATP2B3', 'NTN1', 'CEL', 'NPIPB6', 'FOXD4L5', 'TRRAP', 'CHD5', 'RBMX', 'GOLGA6L2', 'NDUFB11', 'KMT2E', 'HLA-DRB5', 'KCNJ18', 'PLA2G4D', 'RUVBL2', 'ADM', 'OR2T35', 'TUBB8B', 'PRSS1', 'KMT2C', 'FANCD2', 'HLA-B', 'MAGEC1', 'SEC63', 'SHROOM4', 'KRTAP10-6', 'SH2B1', 'USP9X', 'RPL10', 'SIRPA', 'RIN3', 'SPTBN4', 'ZNF880', 'ZXDA', 'FAM86B1', 'ZNG1C', 'ASAH2B', 'MUC3A', 'HLA-A', 'ZNF717', 'SYNE1', 'CP', 'MUC6', 'ADAMTS7', 'PLEC', 'GOLGA6L6', 'DCAF15', 'NEB', 'PRAMEF33', 'RERE', 'KMT2B', 'IRF2BPL', 'SCN4A', 'CACNA1H', 'GLE1', 'INF2', 'RP1L1', 'OBSCN', 'VILL', 'IL32', 'VCX', 'FOXD4L3', 'HLA-DQB1', 'CACNA1I', 'FHOD3', 'SLC34A1', 'MAPK12', 'SYNGAP1', 'KRTAP5-5', 'HSPG2', 'CENPB', 'KRTAP4-8', 'TNXB', 'PCDHA4', 'HIP1', 'PRB3']

    # 1. P-VALUE ≤ 0.3
    df_filtered = df[df["P-VALUE"] <= 0.3].copy()

    # 2. OVERPRIOR_GENE annotation
    df_filtered.insert(
        loc=df_filtered.columns.get_loc("P-VALUE"),
        column="OVERPRIOR_GENE",
        value=df_filtered["GENE_SYMBOL"].apply(lambda g: "YES" if g in gene_list else "")
    )
    out_file = Path(args.input_file).parent / f"{Path(args.input_file).stem}_filtered.tsv"
    df_filtered.to_csv(out_file, sep="\t", index=False)
    print(f"[INFO] Filtered results saved to {out_file}")
if __name__ == "__main__":
    main()