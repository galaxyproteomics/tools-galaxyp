import argparse
import tempfile
import os
import urllib.request
from pathlib import Path


try:
    from mosaicq import calculate_q, calculate_q_alt
    MOSAICQ_AVAILABLE = True
except ImportError:
    MOSAICQ_AVAILABLE = False

# No .format() used — placeholders are replaced with .replace()
# This avoids conflicts between Python's {key} syntax and JavaScript's {key: value}
HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Proteins Mosaic Q. __PDB_ID__</title>
<script src="https://3dmol.csb.pitt.edu/build/3Dmol-min.js"></script>
<style>
  body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #fafafa; }
  h2 { color: #E05A00; }
  .metrics { background: white; border-radius: 8px; padding: 16px;
             display: inline-block; margin: 12px 0;
             box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
  table { border-collapse: collapse; }
  td, th { padding: 8px 16px; border: 1px solid #ddd; }
  th { background: #f5f5f5; }
  .legend { display: flex; flex-wrap: wrap; gap: 10px;
            font-size: 12px; margin: 10px 0; }
  .dot { width: 12px; height: 12px; border-radius: 50%;
         display: inline-block; border: 1px solid #ccc; }
  #viewer { width: 600px; height: 500px; position: relative;
            border-radius: 8px; border: 1px solid #eee; }
</style>
</head>
<body>
<h2>🤠 Proteins Mosaic Q  __PDB_ID__</h2>

<div class="metrics">
  <table>
    <tr><th>Descriptor</th><th>Value</th></tr>
    <tr><td><b>Q</b></td><td>__Q__</td></tr>
    <tr><td><b>Q_alt</b></td><td>__Q_ALT__</td></tr>
  </table>
</div>

<div class="legend">
  <span><span class="dot" style="background:#fff;"></span> Hydrophobic</span>
  <span><span class="dot" style="background:#4CAF7D;"></span> Polar</span>
  <span><span class="dot" style="background:#E8863A;"></span> Acidic</span>
  <span><span class="dot" style="background:#5B8DD9;"></span> Basic</span>
  <span><span class="dot" style="background:#4DD9D9;"></span> Special</span>
</div>

<div id="viewer"></div>

<script>
var pdbData = `__PDB_CONTENT__`;

var viewer = $3Dmol.createViewer(document.getElementById('viewer'), {
    backgroundColor: 'white'
});

viewer.addModel(pdbData, 'pdb');

var colorGroups = [
    {residues: ['ALA','VAL','ILE','LEU','MET','PHE','TYR','TRP'], color: 'white'},
    {residues: ['SER','THR','ASN','GLN'],                         color: 'green'},
    {residues: ['ASP','GLU'],                                     color: 'orange'},
    {residues: ['ARG','HIS','LYS'],                               color: 'blue'},
    {residues: ['CYS','SEC','GLY','PRO'],                         color: 'cyan'},
];

colorGroups.forEach(function(group) {
    group.residues.forEach(function(res) {
        viewer.setStyle({resn: res, hetflag: false}, {sphere: {color: group.color}});
    });
});

viewer.zoomTo({hetflag: false});
viewer.render();
</script>

<p style="font-size:0.85rem; color:#888; margin-top:20px;">
  <a href="https://proteins-mosaic-q.org" target="_blank">proteins-mosaic-q.org</a>
</p>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdb_id", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    pdb_id = args.pdb_id.strip().upper()

    q, q_alt = "N/A", "N/A"
    pdb_content = ""
    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            url = f"https://files.rcsb.org/download/{pdb_id}.pdb"
            filepath = Path(tmpdir) / f"{pdb_id}.pdb"
            try:
                urllib.request.urlretrieve(url, str(filepath))
            except Exception as download_err:
                raise RuntimeError(f"Could not download {pdb_id}: {download_err}")
            if filepath.exists():
                pdb_content = filepath.read_text()
                if MOSAICQ_AVAILABLE:
                    q     = f"{calculate_q(str(filepath)):.4f}"
                    q_alt = f"{calculate_q_alt(str(filepath)):.4f}"
    except Exception as e:
        q, q_alt = f"Error: {e}", "N/A"

    # Escape backticks and ${ for JS template literal
    pdb_content_js = pdb_content.replace('`', '\\`').replace('${', '\\${')

    # Use .replace() for all substitutions — no .format() needed,
    # so JavaScript { } syntax requires no escaping whatsoever
    html = (HTML_TEMPLATE
            .replace("__PDB_ID__",      pdb_id)
            .replace("__Q__",           str(q))
            .replace("__Q_ALT__",       str(q_alt))
            .replace("__PDB_CONTENT__", pdb_content_js))

    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)


if __name__ == "__main__":
    main()
