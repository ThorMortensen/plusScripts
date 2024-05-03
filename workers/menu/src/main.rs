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

    let select = Select::with_theme(&ColorfulTheme::default())
        .with_prompt(prompt_msg)
        .default(0)
        .items(&args.items)
        .default(last_used)
        .interact()
        .unwrap();

    let selected = args.items[select].clone();

    if let Some(path) = save {
        std::fs::write(path, select.to_string()).unwrap();
    }

    print!("{}", selected);
}
