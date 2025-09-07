# IELTS Study Notes

A comprehensive collection of IELTS preparation materials, practice logs, and study resources built with Jekyll and deployed on GitHub Pages.

## 📚 Contents

This repository contains organized study materials for all four IELTS components:

- **01_Listening** - Listening strategies, practice tests, and error logs
- **02_Reading** - Reading techniques, vocabulary, and practice materials
- **03_Writing** - Task 1 & Task 2 strategies, practice essays, and feedback
- **04_Speaking** - Speaking practice logs, vocabulary, and improvement notes

## 🚀 Live Site

Visit the live site: [https://ielts-prepare.dennisleehappy.org](https://ielts-prepare.dennisleehappy.org)

## 🛠️ Local Development

### Prerequisites

- Ruby 3.1+
- Bundler
- Git

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/dennisleehappy/ielts-prepare.git
   cd ielts-prepare
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Serve the site locally:

   ```bash
   bundle exec jekyll serve
   ```

4. Open your browser to `http://localhost:4000`

## 📝 Adding Content

### Practice Logs

Practice logs follow a consistent format with:

- Clear metadata headers (date, task type, topic)
- Structured student responses
- Detailed feedback and analysis
- Band score assessments
- Vocabulary notes
- Action plans for improvement

### File Structure

```
├── 01_Listening/
│   ├── index.md
│   ├── strategy_notes.md
│   └── error_log.md
├── 02_Reading/
│   ├── index.md
│   ├── strategy_notes.md
│   └── vocabulary.md
├── 03_Writing/
│   ├── Task_1/
│   │   ├── 1_strategy/
│   │   ├── 2_practice_log/
│   │   └── 3_error_notebook/
│   └── Task_2/
│       ├── 1_strategy/
│       ├── 2_practice_log/
│       └── 3_error_notebook/
└── 04_Speaking/
    ├── index.md
    ├── practice_logs/
    └── topic_practice_log.md
```

## 🔧 Configuration

The site uses Jekyll with the following key configurations:

- **Theme**: Minima (GitHub Pages compatible)
- **Markdown**: Kramdown with GitHub Flavored Markdown
- **Syntax Highlighting**: Rouge
- **Plugins**: SEO, Sitemap, Feed, Mentions, Pagination

## 📊 Analytics & SEO

The site includes:

- Jekyll SEO Tag for meta tags and Open Graph
- Sitemap generation
- RSS feed
- Social media integration
- Search engine optimization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `bundle exec jekyll serve`
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Links

- [IELTS Official Website](https://www.ielts.org/)
- [Cambridge IELTS Practice Tests](https://www.cambridge.org/)
- [British Council IELTS Resources](https://www.britishcouncil.org/)

---

**Note**: This is a personal study repository. All practice materials and feedback are for educational purposes only.
