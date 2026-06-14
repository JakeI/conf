#!/usr/bin/env python3

import networkx as nx
import xml.etree.ElementTree as ET
import argparse

def generate_ansi_background_color(r, g, b):
    return f'\033[48;2;{r};{g};{b}m'

def generate_ansi_foreground_color(r, g, b):
    return f'\033[38;2;{r};{g};{b}m'

def reset_ansi_color():
    return '\033[0m'

def convert_hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def determine_text_color(r, g, b):
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return (0, 0, 0) if luminance > 0.5 else (255, 255, 255)

def load_graphml_file(file_path):
    return nx.read_graphml(file_path)

def ensure_graph_is_tree(graph):
    if not nx.is_tree(graph):
        raise ValueError("The graph is not a tree")

def parse_graphml_file(file_path):
    tree = ET.parse(file_path)
    return tree.getroot()

def extract_node_colors(root, graph):
    ns = {
        "graphml": "http://graphml.graphdrawing.org/xmlns",
        "y": "http://www.yworks.com/xml/graphml",
    }
    for node in root.findall(".//graphml:node", ns):
        node_id = node.attrib["id"]
        fill_tag = node.find(".//y:Fill", ns)
        color = fill_tag.attrib.get("color", "#FFFFFF") if fill_tag is not None else "#FFFFFF"
        graph.nodes[node_id]["color"] = color

def find_tree_root(graph):
    return next(node for node in graph if graph.in_degree(node) == 0)

def print_tree(graph, root, prefix='', is_last=True):
    node = graph.nodes[root]
    color = node.get("color", "#FFFFFF")
    r, g, b = convert_hex_to_rgb(color)
    color_code = generate_ansi_background_color(r, g, b)
    text_r, text_g, text_b = determine_text_color(r, g, b)
    text_color_code = generate_ansi_foreground_color(text_r, text_g, text_b)
    print(prefix + ('└── ' if is_last else '├── ') + color_code + text_color_code + str(node['label']) + reset_ansi_color())
    prefix += '    ' if is_last else '│   '
    children = list(graph.successors(root))
    for i, child in enumerate(children):
        is_last = (i == len(children) - 1)
        print_tree(graph, child, prefix, is_last)

def print_graphml(graphml_file):
    graph = load_graphml_file(graphml_file)
    ensure_graph_is_tree(graph)
    root = parse_graphml_file(graphml_file)
    extract_node_colors(root, graph)
    tree_root = find_tree_root(graph)
    print_tree(graph, tree_root)

def main():
    parser = argparse.ArgumentParser(description="Print a tree from a GraphML file with colored labels.")
    parser.add_argument("graphml_file", help="Path to the GraphML file")
    args = parser.parse_args()

    print_graphml(args.graphml_file)

if __name__ == "__main__":
    main()

