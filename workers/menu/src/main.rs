use clap::Parser;
use dialoguer::{theme::ColorfulTheme, Select};
use std::path::PathBuf;

/// Create menus for your CLI
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None, )]
struct Args {
    /// A list of of things to serve
    #[arg(short, long,  value_delimiter = ' ', num_args = 1..)]
    items: Vec<String>,

    /// Items provided as delimited strings (newline, literal \n, or pipe)
    #[arg(long = "item-strings", value_name = "ITEM_STRINGS")]
    item_strings: Vec<String>,

    /// Persist path
    #[arg(short, long)]
    persist_path: Option<PathBuf>,

    /// Message to user
    #[arg(short, long)]
    prompt_msg: Option<String>,

    /// Default value
    #[arg(short, long)]
    default: Option<usize>,
}

fn main() {
    let args = Args::parse();
    let mut last_used = 0;
    let mut save = None;

    let items = collect_items(&args);
    if items.is_empty() {
        eprintln!("No menu items provided. Use --items or --item-strings.");
        std::process::exit(1);
    }

    let prompt_msg = match args.prompt_msg {
        Some(msg) => msg,
        None => "Select: ".to_string(),
    };

    if let Some(default) = args.default {
        last_used = default;
    } else if let Some(path) = args.persist_path {
        let home_dir = dirs::home_dir().expect("Home directory not found");
        let base_path = home_dir.join(".plus-script-persist");

        let path = base_path.join(path);

        if path.exists() {
            last_used = std::fs::read_to_string(path.clone())
                .unwrap()
                .parse::<usize>()
                .unwrap();
        } else {
            std::fs::create_dir_all(base_path).unwrap();
        }
        save = Some(path);
    }

    let default_index = last_used.min(items.len().saturating_sub(1));

    let select = Select::with_theme(&ColorfulTheme::default())
        .with_prompt(prompt_msg)
        .items(&items)
        .default(default_index)
        .interact()
        .unwrap();

    let selected = items[select].clone();

    if let Some(path) = save {
        std::fs::write(path, select.to_string()).unwrap();
    }

    print!("{}", selected);
}

fn collect_items(args: &Args) -> Vec<String> {
    let mut items = args.items.clone();

    for chunk in &args.item_strings {
        items.extend(split_item_strings(chunk));
    }

    items.retain(|item| !item.trim().is_empty());
    items
}

fn split_item_strings(raw: &str) -> Vec<String> {
    let normalized = raw.replace("\\n", "\n").replace("||", "\n");

    normalized
        .lines()
        .map(|line| line.trim_end_matches('\r').to_string())
        .collect()
}
