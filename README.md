# optimized_exomiser
Genome Med. 2025 Oct 21;17:127に準拠した最適化設定(Exomiser14.1.0)

<b>1．導入方法</b><br>
基本的な導入方法は<a href="https://github.com/SogataCode/exomiser">exomiserリポジトリ</a>を参照してください。<br>
<code>optimized_script.sh</code><code>optimized_template.yml</code><code>opitimized_example.csv</code><code>postfilter.py</code>をexomiserのインストールフォルダにダウンロードしてください。<br>
最適化設定を利用するためには<code>bcftools</code>, <code>pandas</code>が追加で必要です。<br>
以下の例に従って、環境内に追加してください。
<pre><code class="language-bash">
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda install pandas
conda install bcftools -y
bcftools --version
</code></pre>

<b>2．使い方</b><br>
<u><b>1) Proband-only mode</b></u><br>
csvファイル内のped_pathカラムを空欄にします。<br>
複数サンプルのGenotype情報が含まれるvcfの場合は、proband_idカラムで対象のサンプルIDを指定してください。<br>
単一サンプルのvcfファイルを使う場合は、ped_path, proband_idどちらも空欄で大丈夫です。<br>

<u><b>2) multi_sample mode</b></u><br>
複数サンプルのGenotype情報が含まれるvcfファイルを利用します。<br>
csvファイル内のped_path, proband_idカラムが必須になります。<br>

<u><b>3) 実行</b></u><br>
<pre><code class="language-bash">
bash optimized_script.sh [your.csv]
</code></pre>

<b>3. 出力</b><br>
<code>${sample}_QC_exomiser.variant_filtered.tsv</code>として結果が出力されます。<br>
tsvファイル内のOVERPRIOR_GENE列は過剰に優先順位付けされる病的意義の低い可能性が高い遺伝子です。<br>

<b>4. 仕様</b><br>
<u><b>1) pre filtering</u></b><br>
QC<20, hetero VAF<15%, >85%のコールは除外されます。<br>
<u><b>2) run</u></b><br>
vcfファイル内のサンプル数, ped_path, proband_idの有無に応じて解析を行います。<br>
hiPHIVE(human only), prediction tool=REVEL, MVP, AlphaMissense, SpliceAIを用いてスコアリングされます。<br>
Clinvar whitelistはONになっています。<br>
<u><b>3) post filter</u></b><br>
P-VALUE<0.3のバリアントに限定されます。<br>
過剰に優先順位付けされやすい99遺伝子にフラグを立てます(OVERPRIOR_GENE列の"YES")。<br>
以下論文より引用<br>
ES Exomiser cohort: 99 genes (p ≤ 0.3; present in the top 30 candidates for 5% of cohort)<br>
MUC4, GJC2, TDG, NFIA, SREBF1, TTN, MYH6, AP3S1, ATAT1, HLA-DRB1, PRKRA, ANAPC1, MRPL4, ASXL3, PRPF40B, TYRO3, TRA2A, VPS13B, SKA3, CCDC124, WIPF3, BICRA, MED13L, ATP2B3, NTN1, CEL, NPIPB6, FOXD4L5, TRRAP, CHD5, RBMX, GOLGA6L2, NDUFB11, KMT2E, HLA-DRB5, KCNJ18, PLA2G4D, RUVBL2, ADM, OR2T35, TUBB8B, PRSS1, KMT2C, FANCD2, HLA-B, MAGEC1, SEC63, SHROOM4, KRTAP10-6, SH2B1, USP9X, RPL10, SIRPA, RIN3, SPTBN4, ZNF880, ZXDA, FAM86B1, ZNG1C, ASAH2B, MUC3A, HLA-A, ZNF717, SYNE1, CP, MUC6, ADAMTS7, PLEC, GOLGA6L6, DCAF15, NEB, PRAMEF33, RERE, KMT2B, IRF2BPL, SCN4A, CACNA1H, GLE1, INF2, RP1L1, OBSCN, VILL, IL32, VCX, FOXD4L3, HLA-DQB1, CACNA1I, FHOD3, SLC34A1, MAPK12, SYNGAP1, KRTAP5-5, HSPG2, CENPB, KRTAP4-8, TNXB, PCDHA4, HIP1, PRB3


