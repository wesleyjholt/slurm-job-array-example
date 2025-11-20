# Dummy simulation code. Reads parameters from a YAML file and writes them to {output_dir}/results.txt.

import argparse
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--input_yaml', default='$INPUT_YAML')
parser.add_argument('--output_dir', default='$OUTPUT_DIR')
args = parser.parse_args()

with open(args.input_yaml) as f:
    data = yaml.safe_load(f)

output_file = f"{args.output_dir}/result.txt"
with open(output_file, 'w') as f:
    f.write(f"Parameter 1: {data['parameter1']}\n")
    f.write(f"Parameter 2: {data['parameter2']}\n")
print(f"Simulation completed. Results saved to {output_file}")