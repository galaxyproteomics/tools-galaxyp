"""Small, static reference tables bundled with the tool (no external data).

COG functional categories follow the NCBI COG database (2020/2024 updates).
EC classes follow the IUBMB Enzyme Nomenclature. TC classes follow TCDB.
CAZy classes follow the CAZy database. Grouping of KEGG-Decoder functions
into categories is our own and only affects layout.
"""

# letter: (group, English, Bulgarian)
COG_CATEGORIES = {
    "J": ("info", "Translation, ribosomal structure and biogenesis", "Транслация, рибозомна структура и биогенеза"),
    "A": ("info", "RNA processing and modification", "Обработка и модификация на РНК"),
    "K": ("info", "Transcription", "Транскрипция"),
    "L": ("info", "Replication, recombination and repair", "Репликация, рекомбинация и репарация"),
    "B": ("info", "Chromatin structure and dynamics", "Структура и динамика на хроматина"),
    "D": ("cell", "Cell cycle control, cell division, chromosome partitioning", "Клетъчен цикъл, делене, разпределяне на хромозомите"),
    "Y": ("cell", "Nuclear structure", "Ядрена структура"),
    "V": ("cell", "Defense mechanisms", "Защитни механизми"),
    "T": ("cell", "Signal transduction mechanisms", "Сигнална трансдукция"),
    "M": ("cell", "Cell wall/membrane/envelope biogenesis", "Биогенеза на клетъчна стена и мембрана"),
    "N": ("cell", "Cell motility", "Клетъчна подвижност"),
    "Z": ("cell", "Cytoskeleton", "Цитоскелет"),
    "W": ("cell", "Extracellular structures", "Извънклетъчни структури"),
    "U": ("cell", "Intracellular trafficking, secretion, and vesicular transport", "Вътреклетъчен транспорт, секреция и везикули"),
    "O": ("cell", "Posttranslational modification, protein turnover, chaperones", "Посттранслационни модификации, оборот на белтъци, шаперони"),
    "X": ("cell", "Mobilome: prophages, transposons", "Мобилом: профаги, транспозони"),
    "C": ("metab", "Energy production and conversion", "Производство и преобразуване на енергия"),
    "G": ("metab", "Carbohydrate transport and metabolism", "Транспорт и метаболизъм на въглехидрати"),
    "E": ("metab", "Amino acid transport and metabolism", "Транспорт и метаболизъм на аминокиселини"),
    "F": ("metab", "Nucleotide transport and metabolism", "Транспорт и метаболизъм на нуклеотиди"),
    "H": ("metab", "Coenzyme transport and metabolism", "Транспорт и метаболизъм на коензими"),
    "I": ("metab", "Lipid transport and metabolism", "Транспорт и метаболизъм на липиди"),
    "P": ("metab", "Inorganic ion transport and metabolism", "Транспорт и метаболизъм на неорганични йони"),
    "Q": ("metab", "Secondary metabolites biosynthesis, transport and catabolism", "Вторични метаболити: биосинтеза, транспорт, катаболизъм"),
    "R": ("poor", "General function prediction only", "Само обща функционална прогноза"),
    "S": ("poor", "Function unknown", "Неизвестна функция"),
}

COG_GROUPS = {
    "info": ("Information storage and processing", "Съхранение и обработка на информация"),
    "cell": ("Cellular processes and signaling", "Клетъчни процеси и сигнализация"),
    "metab": ("Metabolism", "Метаболизъм"),
    "poor": ("Poorly characterized", "Слабо охарактеризирани"),
}

EC_CLASSES = {
    "1": ("Oxidoreductases", "Оксидоредуктази"),
    "2": ("Transferases", "Трансферази"),
    "3": ("Hydrolases", "Хидролази"),
    "4": ("Lyases", "Лиази"),
    "5": ("Isomerases", "Изомерази"),
    "6": ("Ligases", "Лигази"),
    "7": ("Translocases", "Транслокази"),
}

TC_CLASSES = {
    "1": ("Channels and pores", "Канали и пори"),
    "2": ("Electrochemical potential-driven transporters", "Транспортери, задвижвани от електрохимичен потенциал"),
    "3": ("Primary active transporters", "Първично активни транспортери"),
    "4": ("Group translocators", "Групови транслокатори"),
    "5": ("Transmembrane electron carriers", "Трансмембранни електронни преносители"),
    "8": ("Accessory factors involved in transport", "Помощни фактори в транспорта"),
    "9": ("Incompletely characterized transport systems", "Непълно охарактеризирани транспортни системи"),
}

CAZY_CLASSES = {
    "GH": ("Glycoside hydrolases", "Гликозид хидролази"),
    "GT": ("Glycosyltransferases", "Гликозилтрансферази"),
    "PL": ("Polysaccharide lyases", "Полизахаридни лиази"),
    "CE": ("Carbohydrate esterases", "Въглехидратни естерази"),
    "AA": ("Auxiliary activities", "Спомагателни активности"),
    "CBM": ("Carbohydrate-binding modules", "Въглехидрат-свързващи модули"),
}

# KEGG overview/global maps: very large, hide from "top pathways" by default
KEGG_GLOBAL_MAP_PREFIXES = ("map011", "map012")

# Layout groups for the 178 KEGG-Decoder functions (names as in KEGG-Decoder)
_MIXED = [f for f in (
    "Mixed acid: Lactate", "Mixed acid: Formate", "Mixed acid: Formate to CO2 & H2",
    "Mixed acid: Acetate", "Mixed acid: Ethanol, Acetate to Acetylaldehyde",
    "Mixed acid: Ethanol, Acetyl-CoA to Acetylaldehyde (reversible)",
    "Mixed acid: Ethanol, Acetylaldehyde to Ethanol",
    "Mixed acid: PEP to Succinate via OAA, malate & fumarate")]

DECODER_GROUPS = [
    ("carbon", "Central carbon metabolism", "Централен въглероден метаболизъм", [
        "glycolysis", "gluconeogenesis", "TCA Cycle", "Entner-Doudoroff Pathway",
        "Glyoxylate shunt", "Anaplerotic genes"]),
    ("ferment", "Fermentation", "Ферментация", _MIXED),
    ("energy", "Respiration and energy", "Дишане и енергия", [
        "NAD(P)H-quinone oxidoreductase", "NADH-quinone oxidoreductase",
        "Na-NADH-ubiquinone oxidoreductase", "F-type ATPase", "V-type ATPase",
        "Cytochrome c oxidase", "Ubiquinol-cytochrome c reductase",
        "Cytochrome o ubiquinol oxidase", "Cytochrome aa3-600 menaquinol oxidase",
        "Cytochrome c oxidase, cbb3-type", "Cytochrome bd complex"]),
    ("fixation", "Carbon fixation and C1", "Фиксация на въглерод и C1", [
        "RuBisCo", "CBB Cycle", "rTCA Cycle", "Wood-Ljungdahl", "3-Hydroxypropionate Bicycle",
        "4-Hydroxybutyrate/3-hydroxypropionate", "Serine pathway/formaldehyde assimilation",
        "Soluble methane monooxygenase", "methanol dehydrogenase", "alcohol oxidase",
        "dimethylamine/trimethylamine dehydrogenase"]),
    ("methano", "Methanogenesis", "Метаногенеза", [
        "Methanogenesis via methanol", "Methanogenesis via acetate",
        "Methanogenesis via dimethylsulfide, methanethiol, methylpropanoate",
        "Methanogenesis via methylamine", "Methanogenesis via trimethylamine",
        "Methanogenesis via dimethylamine", "Methanogenesis via CO2",
        "Coenzyme B/Coenzyme M regeneration", "Coenzyme M reduction to methane"]),
    ("photo", "Phototrophy", "Фототрофия", [
        "Photosystem II", "Photosystem I", "Cytochrome b6/f complex",
        "anoxygenic type-II reaction center", "anoxygenic type-I reaction center"]),
    ("nitrogen", "Nitrogen cycle", "Азотен цикъл", [
        "ammonia oxidation (amo/pmmo)", "hydroxylamine oxidation", "nitrite oxidation",
        "dissim nitrate reduction", "DNRA", "nitrite reduction", "nitric oxide reduction",
        "nitrous-oxide reduction", "nitrogen fixation", "hydrazine dehydrogenase",
        "hydrazine synthase"]),
    ("sulfur", "Sulfur cycle", "Серен цикъл", [
        "dissimilatory sulfate < > APS", "dissimilatory sulfite < > APS",
        "dissimilatory sulfite < > sulfide", "thiosulfate oxidation",
        "alt thiosulfate oxidation tsdA", "alt thiosulfate oxidation doxAD",
        "sulfur reductase sreABC", "thiosulfate/polysulfide reductase", "sulfhydrogenase",
        "sulfur disproportionation", "sulfur dioxygenase", "sulfite dehydrogenase",
        "sulfite dehydrogenase (quinone)", "sulfide oxidation", "sulfur assimilation",
        "DMSP demethylation", "DMS dehydrogenase", "DMSO reductase", "Sulfolipid biosynthesis"]),
    ("hydrogen", "Hydrogen metabolism", "Водороден метаболизъм", [
        "NiFe hydrogenase", "ferredoxin hydrogenase", "membrane-bound hydrogenase",
        "hydrogen:quinone oxidoreductase", "NAD-reducing hydrogenase",
        "NADP-reducing hydrogenase", "NiFe hydrogenase Hyd-1"]),
    ("polysacch", "Polysaccharide degradation", "Разграждане на полизахариди", [
        "pectinesterase", "diacetylchitobiose deacetylase", "glucoamylase",
        "D-galacturonate epimerase", "exo-poly-alpha-galacturonosidase",
        "oligogalacturonide lyase", "cellulase", "exopolygalacturonase", "chitinase",
        "basic endochitinase B", "bifunctional chitinase/lysozyme",
        "beta-N-acetylhexosaminidase", "D-galacturonate isomerase", "alpha-amylase",
        "beta-glucosidase", "pullulanase"]),
    ("storage", "Storage compounds", "Резервни вещества", [
        "starch/glycogen synthesis", "starch/glycogen degradation",
        "polyhydroxybutyrate synthesis", "bidirectional polyphosphate"]),
    ("amino", "Amino acid biosynthesis", "Биосинтеза на аминокиселини", [
        "histidine", "arginine", "lysine", "serine", "threonine", "asparagine", "glutamine",
        "cysteine", "glycine", "proline", "alanine", "valine", "methionine", "phenylalanine",
        "isoleucine", "leucine", "tryptophan", "tyrosine", "aspartate", "glutamate"]),
    ("vitamins", "Vitamins and cofactors", "Витамини и кофактори", [
        "thiamin biosynthesis", "riboflavin biosynthesis", "cobalamin biosynthesis"]),
    ("terpen", "Terpenoids and carotenoids", "Терпеноиди и каротеноиди", [
        "mevalonate pathway", "MEP-DOXP pathway", "carotenoids backbone biosynthesis",
        "end-product astaxanthin", "end-product nostoxanthin",
        "end-product zeaxanthin diglucoside", "end-product myxoxanthophylls",
        "staphyloaxanthin biosynthesis", "Retinal biosynthesis", "Retinal from apo-carotenals"]),
    ("transport", "Transporters", "Транспортери", [
        "transporter: vitamin B12", "transporter: thiamin", "transporter: urea",
        "transporter: phosphonate", "transporter: phosphate", "Cobalt transporter CbiMQ",
        "Cobalt transporter CbtA", "Cobalt transporter CorA",
        "Nickel ABC-type substrate-binding NikA", "Copper transporter CopA",
        "Ferrous iron transporter FeoB", "Ferric iron ABC-type substrate-binding AfuA",
        "Fe-Mn transporter MntH"]),
    ("secretion", "Secretion systems", "Секреторни системи", [
        "Type I Secretion", "Type II Secretion", "Type III Secretion", "Type IV Secretion",
        "Type Vabc Secretion", "Type VI Secretion", "Sec-SRP", "Twin Arginine Targeting"]),
    ("surface", "Motility, biofilm and competence", "Подвижност, биофилм и компетентност", [
        "Flagellum", "Chemotaxis", "Biofilm PGA Synthesis protein",
        "Colanic acid and Biofilm transcriptional regulator", "Biofilm regulator BssS",
        "Colanic acid and Biofilm protein A", "Curli fimbriae biosynthesis", "Adhesion",
        "Competence-related core components", "Competence-related related components",
        "Competence factors"]),
    ("degrade", "Degradation and detoxification", "Разграждане и детоксикация", [
        "Naphthalene degradation to salicylate", "PET degradation", "Arsenic reduction",
        "C-P lyase cleavage PhnJ", "CP-lyase complex", "CP-lyase operon"]),
]

# TC subclasses (TC system, approved by IUBMB). Checked against www.tcdb.org, October 2026.
TC_SUBCLASSES = {
    "1.A": "α-type channels", "1.B": "β-barrel porins", "1.C": "Pore-forming toxins",
    "1.D": "Non-ribosomally synthesized channels", "1.E": "Holins", "1.F": "Vesicle fusion pores",
    "1.G": "Viral fusion pores", "1.H": "Paracellular channels", "1.I": "Membrane-bounded channels",
    "1.J": "Virion egress pyramidal apertures", "1.K": "Phage DNA injection channels",
    "1.L": "Tunneling nanotubes", "1.M": "Membrane fusion-mediating spanins",
    "2.A": "Porters (uniporters, symporters, antiporters)", "2.B": "Non-ribosomally synthesized porters",
    "2.C": "Ion-gradient-driven energizers", "2.D": "Transcompartment lipid carriers",
    "3.A": "P-P-bond hydrolysis-driven transporters", "3.B": "Decarboxylation-driven transporters",
    "3.C": "Methyltransfer-driven transporters", "3.D": "Oxidoreduction-driven transporters",
    "3.E": "Light absorption-driven transporters",
    "4.A": "Phosphotransfer-driven group translocators (PTS)", "4.B": "Nicotinamide ribonucleoside uptake transporters",
    "4.C": "Acyl-CoA ligase-coupled transporters", "4.D": "Polysaccharide synthase/exporters",
    "4.E": "Vacuolar polyphosphate polymerase-catalyzed group translocators", "4.F": "Choline/ethanolamine phosphotransferase 1 (CEPT1)",
    "5.A": "Transmembrane 2-electron transfer carriers", "5.B": "Transmembrane 1-electron transfer carriers",
    "8.A": "Auxiliary transport proteins", "8.B": "Ribosomally synthesized protein/peptide toxins/agonists that target channels and carriers",
    "8.C": "Non-ribosomally synthesized toxins that target channels, carriers and pumps",
    "9.A": "Recognized transporters of unknown biochemical mechanism", "9.B": "Putative transport proteins",
    "9.C": "Functionally characterized transporters lacking identified sequences",
}

# Short names of common TC families, shortened from TCDB names (leading 'The' and trailing
# 'Family'/'Superfamily' dropped, TCDB abbreviations kept). Checked against www.tcdb.org, October 2026.
TC_FAMILIES = {
    "1.A.1": "Voltage-gated ion channel (VIC)", "1.A.8": "Major intrinsic aquaporin protein (MIP)",
    "1.A.11": "Ammonium channel transporter (Amt)", "1.A.22": "Large-conductance mechanosensitive channel (MscL)",
    "1.A.23": "Small-conductance mechanosensitive channel (MscS)", "1.A.30": "H+/Na+-translocating flagellar motor / ExbBD energizer (Mot-Exb)",
    "1.A.35": "CorA metal ion transporter (MIT)", "1.B.1": "General bacterial porin (GBP)",
    "1.B.14": "Outer membrane receptor (OMR)", "1.B.17": "Outer membrane factor (OMF)",
    "1.B.33": "Outer membrane protein insertion porin, Bam complex (OmpIP)",
    "2.A.1": "Major facilitator superfamily (MFS)", "2.A.3": "Amino acid–polyamine–organocation (APC)",
    "2.A.4": "Cation diffusion facilitator (CDF)", "2.A.6": "Resistance–nodulation–cell division (RND)",
    "2.A.7": "Drug/metabolite transporter (DMT)", "2.A.9": "Membrane protein insertase (YidC/Alb3/Oxa1)",
    "2.A.13": "C4-dicarboxylate uptake (Dcu)", "2.A.14": "Lactate permease (LctP)",
    "2.A.17": "Proton-dependent oligopeptide transporter (POT/PTR)", "2.A.20": "Inorganic phosphate transporter (PiT)",
    "2.A.21": "Solute:sodium symporter (SSS)", "2.A.22": "Neurotransmitter:sodium symporter (NSS)",
    "2.A.23": "Dicarboxylate/amino acid:cation symporter (DAACS)",
    "2.A.25": "Alanine or glycine:cation symporter (AGCS)",
    "2.A.26": "Branched-chain amino acid:cation symporter (LIVCS)",
    "2.A.36": "Monovalent cation:proton antiporter-1 (CPA1)", "2.A.37": "Monovalent cation:proton antiporter-2 (CPA2)",
    "2.A.40": "Nucleobase:cation symporter-2 (NCS2)", "2.A.47": "Divalent anion:Na+ symporter (DASS)",
    "2.A.53": "Sulfate permease (SulP)", "2.A.55": "Metal ion transporter (Nramp)",
    "2.A.56": "Tripartite ATP-independent periplasmic transporter (TRAP-T)",
    "2.A.58": "Phosphate:Na+ symporter (PNaS)", "2.A.63": "Monovalent cation (K+ or Na+):proton antiporter-3 (CPA3)",
    "2.A.64": "Twin-arginine targeting (Tat)",
    "2.A.66": "Multidrug/oligosaccharidyl-lipid/polysaccharide flippase (MOP)",
    "2.A.69": "Auxin efflux carrier (AEC)", "2.A.72": "K+ uptake permease (KUP)",
    "2.C.1": "TonB–ExbB–ExbD / TolA–TolQ–TolR energizers",
    "3.A.1": "ATP-binding cassette (ABC) superfamily", "3.A.2": "H+- or Na+-translocating F-, V- and A-type ATPases (F-ATPase)",
    "3.A.3": "P-type ATPases (P-ATPase)", "3.A.4": "Arsenite–antimonite efflux (ArsAB)",
    "3.A.5": "General secretory pathway (Sec)", "3.A.6": "Type III secretory pathway (IIISP)",
    "3.A.7": "Type IV secretory pathway (IVSP)", "3.A.15": "Outer membrane protein secreting main terminal branch (MTB, type II secretion)",
    "3.A.23": "Type VI secretion system (T6SS)",
    "3.D.1": "H+ or Na+-translocating NADH dehydrogenase (NDH)", "3.D.2": "Proton-translocating transhydrogenase (PTH)",
    "3.D.3": "Proton-translocating quinol:cytochrome c reductase (QCR)", "3.D.4": "Proton-translocating cytochrome oxidase (COX)",
    "4.A.1": "PTS glucose–glucoside (Glc) family", "4.A.2": "PTS fructose–mannitol (Fru) family",
    "4.A.3": "PTS lactose–chitobiose–β-glucoside (Lac) family", "4.A.6": "PTS mannose–fructose–sorbose (Man) family",
}

# Main activity of common CAZy families: short summaries written for this tool and checked
# against the activities listed on each CAZy family page (www.cazy.org/<family>.html), October 2026.
# The CAZy page lists all known activities.
CAZY_FAMILIES = {
    "GH1": "β-glucosidase", "GH2": "β-galactosidase", "GH3": "β-glucosidase / β-N-acetylglucosaminidase",
    "GH4": "NAD-dependent α-glucosidase / α-galactosidase / 6-P-glucosidase", "GH5": "endo-β-1,4-glucanase / mannanase (diverse)",
    "GH6": "cellobiohydrolase / endo-β-1,4-glucanase", "GH8": "endoglucanase / chitosanase / xylanase", "GH9": "endoglucanase",
    "GH10": "endo-β-1,4-xylanase", "GH11": "endo-β-1,4-xylanase", "GH12": "endoglucanase / xyloglucanase",
    "GH13": "α-amylase family (starch and glycogen enzymes)", "GH14": "β-amylase",
    "GH15": "glucoamylase / glucodextranase", "GH16": "β-1,3/1,4-glucanase, laminarinase, agarase",
    "GH17": "β-1,3-glucanase", "GH18": "chitinase", "GH19": "chitinase", "GH20": "β-hexosaminidase",
    "GH23": "lytic transglycosylase (peptidoglycan)", "GH24": "lysozyme", "GH25": "lysozyme",
    "GH26": "β-mannanase", "GH27": "α-galactosidase", "GH28": "polygalacturonase", "GH29": "α-L-fucosidase",
    "GH30": "glucosylceramidase / β-xylosidase / β-1,6-galactanase", "GH31": "α-glucosidase / α-xylosidase",
    "GH32": "invertase / fructanase", "GH33": "sialidase", "GH35": "β-galactosidase",
    "GH36": "α-galactosidase", "GH37": "trehalase", "GH38": "α-mannosidase", "GH39": "β-xylosidase / α-L-iduronidase",
    "GH42": "β-galactosidase", "GH43": "β-xylosidase / α-L-arabinofuranosidase / arabinanase",
    "GH44": "endoglucanase / xyloglucanase", "GH46": "chitosanase", "GH48": "cellobiohydrolase",
    "GH51": "α-L-arabinofuranosidase", "GH53": "endo-β-1,4-galactanase",
    "GH57": "α-amylase / 4-α-glucanotransferase", "GH63": "α-glucosidase (incl. ER processing glucosidase I)",
    "GH64": "β-1,3-glucanase", "GH65": "trehalose / maltose phosphorylase",
    "GH73": "β-N-acetylglucosaminidase (peptidoglycan)", "GH74": "xyloglucanase",
    "GH77": "4-α-glucanotransferase (amylomaltase)", "GH78": "α-L-rhamnosidase",
    "GH84": "β-N-acetylglucosaminidase", "GH85": "endo-β-N-acetylglucosaminidase",
    "GH88": "unsaturated glucuronyl hydrolase", "GH92": "α-mannosidase",
    "GH94": "cellobiose / chitobiose phosphorylase", "GH95": "α-L-fucosidase",
    "GH103": "lytic transglycosylase (peptidoglycan)", "GH104": "lytic transglycosylase (peptidoglycan)",
    "GH105": "unsaturated rhamnogalacturonyl hydrolase", "GH106": "α-L-rhamnosidase",
    "GH108": "N-acetylmuramidase", "GH109": "α-N-acetylgalactosaminidase",
    "GH114": "endo-α-1,4-polygalactosaminidase", "GH127": "β-L-arabinofuranosidase",
    "GH130": "β-mannoside phosphorylase", "GH133": "glycogen debranching (amylo-α-1,6-glucosidase)",
    "GT1": "UDP-glycosyltransferase", "GT2": "inverting glycosyltransferase (cellulose/chitin synthase-like)",
    "GT4": "retaining glycosyltransferase (group 1)", "GT5": "glycogen / starch synthase",
    "GT8": "retaining glycosyltransferase (LPS, glycogenin-like)", "GT9": "heptosyltransferase (LPS core)",
    "GT19": "lipid-A-disaccharide synthase", "GT20": "trehalose-6-phosphate synthase",
    "GT25": "LPS galactosyltransferase", "GT26": "β-ManNAc / ManNAcA transferase (also Gal, Glc)",
    "GT28": "MurG / MGDG synthase", "GT30": "Kdo transferase (WaaA)", "GT35": "glycogen / starch phosphorylase",
    "GT39": "protein O-mannosyltransferase", "GT41": "O-GlcNAc transferase",
    "GT51": "peptidoglycan glycosyltransferase", "GT53": "arabinosyltransferase (EmbA/B/C)",
    "GT81": "glucosyl-3-phosphoglycerate synthase", "GT83": "lipid A aminoarabinose transferase (ArnT)",
    "GT84": "cyclic β-1,2-glucan synthase", "GT85": "arabinofuranosyltransferase (AftA)",
    "GT87": "polyprenyl-phosphomannose-dependent mannosyltransferase",
    "PL1": "pectate lyase", "PL3": "pectate lyase", "PL4": "rhamnogalacturonan lyase",
    "PL6": "alginate lyase / chondroitinase", "PL7": "alginate lyase", "PL8": "hyaluronate / chondroitin lyase",
    "PL9": "pectate lyase", "PL10": "pectate lyase", "PL11": "rhamnogalacturonan lyase",
    "PL12": "heparin-sulfate lyase", "PL22": "oligogalacturonate lyase",
    "CE1": "acetyl xylan esterase and other esterases", "CE3": "acetyl xylan esterase",
    "CE4": "polysaccharide deacetylase (chitin, peptidoglycan, xylan)",
    "CE7": "acetyl xylan esterase / cephalosporin-C deacetylase", "CE8": "pectin methylesterase",
    "CE9": "N-acetylglucosamine-6-phosphate deacetylase", "CE11": "UDP-3-O-acyl-GlcNAc deacetylase (LpxC)",
    "CE12": "pectin / rhamnogalacturonan acetylesterase", "CE14": "GlcNAc-PI / chitobiose deacetylase; mycothiol S-conjugate amidase",
    "CE15": "4-O-methyl-glucuronoyl esterase",
    "AA1": "laccase / multicopper oxidase", "AA2": "class II peroxidase", "AA3": "GMC oxidoreductase",
    "AA4": "vanillyl-alcohol oxidase", "AA5": "copper radical oxidase", "AA6": "1,4-benzoquinone reductase",
    "AA7": "glucooligosaccharide oxidase", "AA10": "lytic polysaccharide monooxygenase (chitin/cellulose)",
    "CBM1": "cellulose-binding", "CBM2": "cellulose / chitin / xylan-binding", "CBM3": "cellulose-binding",
    "CBM4": "xylan / glucan-binding", "CBM5": "chitin-binding", "CBM6": "xylan / glucan-binding",
    "CBM9": "cellulose-binding (in xylanases)", "CBM10": "cellulose-binding", "CBM12": "chitin-binding",
    "CBM13": "ricin B-like (xylan / mannose-binding)", "CBM16": "cellulose / glucomannan-binding",
    "CBM20": "starch-binding", "CBM25": "starch-binding", "CBM26": "starch-binding",
    "CBM32": "galactose / LacNAc-binding", "CBM34": "starch-binding",
    "CBM35": "xylan / mannan / β-galactan-binding", "CBM41": "α-glucan-binding",
    "CBM44": "cellulose / xyloglucan-binding", "CBM48": "glycogen-binding (with GH13)",
    "CBM50": "peptidoglycan / chitin-binding (LysM)", "CBM61": "β-1,4-galactan-binding",
    "CBM63": "cellulose-binding (expansin-like)", "CBM66": "fructan-binding",
    "CBM67": "L-rhamnose-binding", "CBM73": "chitin-binding",
}

# Substrate groups for degradative CAZy families (figure "CAZy by substrate").
# Which groups a family can act on is derived from the dbCAN-sub family-substrate
# mapping (Zheng et al. 2023, NAR 51:W115) by scripts/build_cazy_substrates.py and
# stored in refdata_cazy/cazy_substrates.tsv. The main group below is our reading of
# the family's main activity (CAZY_FAMILIES, checked against the CAZy pages); the
# build refuses a main group that dbCAN does not list for that family.
CAZY_SUBSTRATE_GROUPS = [  # key, English, Bulgarian (display order)
    ("cellulose", "Cellulose and β-glucans", "Целулоза и β-глюкани"),
    ("hemicellulose", "Hemicellulose (xylan, mannan, xyloglucan)", "Хемицелулоза (ксилан, манан, ксилоглюкан)"),
    ("pectin", "Pectin (incl. arabinan, galactan)", "Пектин (вкл. арабинан, галактан)"),
    ("starch", "Starch, glycogen and α-glucans", "Нишесте, гликоген и α-глюкани"),
    ("sucrose", "Sucrose and fructans", "Захароза и фруктани"),
    ("trehalose", "Trehalose", "Трехалоза"),
    ("chitin", "Chitin and chitosan", "Хитин и хитозан"),
    ("peptidoglycan", "Peptidoglycan (incl. own cell wall)", "Пептидогликан (вкл. собствената стена)"),
    ("host", "Host and animal glycans", "Гликани на гостоприемника"),
    ("algal", "Algal polysaccharides", "Водораслови полизахариди"),
    ("lignin", "Lignin", "Лигнин"),
    ("other", "Other glycans and glycosides", "Други гликани и гликозиди"),
]

CAZY_MAIN_SUBSTRATE = {
    "GH6": "cellulose", "GH9": "cellulose", "GH12": "cellulose", "GH13": "starch", "GH14": "starch", "GH15": "starch",
    "GH17": "cellulose", "GH18": "chitin", "GH19": "chitin", "GH23": "peptidoglycan", "GH24": "peptidoglycan",
    "GH25": "peptidoglycan", "GH26": "hemicellulose", "GH28": "pectin", "GH29": "host", "GH32": "sucrose", "GH33": "host",
    "GH37": "trehalose", "GH43": "hemicellulose", "GH44": "cellulose", "GH46": "chitin", "GH48": "cellulose",
    "GH53": "pectin", "GH57": "starch", "GH64": "cellulose", "GH73": "peptidoglycan", "GH74": "hemicellulose",
    "GH77": "starch", "GH84": "host", "GH85": "host", "GH95": "host", "GH103": "peptidoglycan", "GH104": "peptidoglycan",
    "GH105": "pectin", "GH106": "pectin", "GH108": "peptidoglycan", "GH109": "host", "GH133": "starch",
    "GH10": "hemicellulose", "GH11": "hemicellulose",
    "PL1": "pectin", "PL3": "pectin", "PL4": "pectin", "PL6": "algal", "PL7": "algal", "PL8": "host", "PL9": "pectin",
    "PL10": "pectin", "PL11": "pectin", "PL12": "host", "PL22": "pectin",
    "CE1": "hemicellulose", "CE3": "hemicellulose", "CE8": "pectin", "CE12": "pectin",
    "AA1": "lignin", "AA2": "lignin", "AA4": "lignin", "AA5": "lignin", "AA6": "lignin",
    "CBM1": "cellulose", "CBM3": "cellulose", "CBM5": "chitin", "CBM9": "cellulose", "CBM10": "cellulose",
    "CBM12": "chitin", "CBM20": "starch", "CBM25": "starch", "CBM26": "starch", "CBM34": "starch",
    "CBM48": "starch", "CBM50": "peptidoglycan", "CBM61": "pectin", "CBM63": "cellulose", "CBM66": "sucrose",
    "CBM73": "chitin",
}

# Families left out of the substrate figure: they build or modify cell components
# rather than degrade glycans (dbCAN still lists a substrate for them).
CAZY_SUBSTRATE_EXCLUDE = {
    "CE9": "N-acetylglucosamine-6-phosphate deacetylase (NagA), intracellular amino-sugar metabolism",
    "CE11": "UDP-3-O-acyl-GlcNAc deacetylase (LpxC), lipid A biosynthesis",
    "CE14": "GlcNAc-PI / mycothiol-pathway deacetylases, biosynthesis",
}

# Cell overview: KOs used directly (not through a metabolic function), checked against
# KEGG KO entries on 2026-10-22. Envelope: diderm when lpxC, lptD and bamA are all present.
CELL_EXTRA_KOS = {
    "K02535": "lpxC", "K04744": "lptD", "K07277": "bamA",            # LPS outer-membrane markers
    "K00677": "lpxA", "K02536": "lpxD",                              # lipid A synthesis
    "K00790": "murA", "K00075": "murB", "K01924": "murC", "K01928": "murE",
    "K01000": "mraY", "K02563": "murG",                              # peptidoglycan synthesis (cell wall)
    "K03612": "rnfG", "K03613": "rnfE", "K03614": "rnfD", "K03615": "rnfC",
    "K03616": "rnfB", "K03617": "rnfA",                              # Rnf complex
    "K21573": "susC", "K21572": "susD",                              # Bacteroidetes polysaccharide utilisation loci
    "K14743": "mycP", "K14956": "esxA",                              # ESX (type VII) secretion, Actinobacteria
    "K00239": "sdhA", "K00240": "sdhB", "K00241": "sdhC", "K00242": "sdhD",  # succinate dehydrogenase / fumarate reductase
    "K03885": "ndh",                                                  # type II NADH dehydrogenase
    "K03886": "qcrA", "K03887": "qcrB", "K03888": "qcrC",             # menaquinol-cytochrome c reductase, Bacillus type
    "K03889": "qcrC", "K03890": "qcrA", "K03891": "qcrB",             # menaquinol-cytochrome c reductase (bcc, Actinobacteria)
}

# KOs that the element-cycle diagrams read directly, beyond the KEGG-Decoder functions:
# assimilatory sulfate reduction as in KEGG module M00176 (identifiers only, no KEGG content).
CYCLE_EXTRA_KOS = {
    "K00958": "sat",                                    # ATP sulfurylase, single-chain type
    "K00957": "cysD", "K00956": "cysN",                 # ATP sulfurylase, two-subunit type (Proteobacteria)
    "K00955": "cysNC",                                  # bifunctional ATP sulfurylase / APS kinase
    "K00860": "cysC",                                   # APS kinase (APS -> PAPS)
    "K00390": "cysH",                                   # PAPS / APS reductase (-> sulfite)
    # nitrogen: respiratory DNRA versus assimilation
    "K03385": "nrfA", "K15876": "nrfH",                 # cytochrome c nitrite reductase (respiratory DNRA)
    "K00362": "nirB", "K00363": "nirD", "K00366": "nirA",  # NAD(P)H / ferredoxin nitrite reductases (assimilation)
    "K00372": "nasA", "K00367": "narB", "K10534": "NR",  # assimilatory nitrate reductases
    # C1: formaldehyde assimilation
    "K08691": "mcl",                                    # malyl-CoA lyase, marker of the serine cycle
    "K00855": "prk",                                    # phosphoribulokinase, needed with RuBisCO for the CBB cycle
    "K08093": "hxlA", "K08094": "hxlB",                 # RuMP pathway: 3-hexulose-6-phosphate synthase / isomerase
    "K13812": "fae-hps", "K13831": "hps-phi",           # fused RuMP enzymes
    # catalytic subunits that a step needs before its accessory subunits count
    "K00370": "narG", "K02567": "napA", "K04561": "norB",
    "K02586": "nifD",                                   # nitrogenase alpha (eggNOG gives Vnf/Anf the same KO)
    "K10944": "amoA/pmoA", "K16157": "mmoX",
    "K08352": "phsA", "K21307": "soeA", "K05301": "sorA", "K17224": "soxB",
    "K00394": "aprA", "K11180": "dsrA",
}
