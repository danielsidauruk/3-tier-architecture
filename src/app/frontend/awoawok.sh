git reset --soft HEAD~1
git add ../app/
git restore --stage ../app/backend/test_api.sh
git commit -m "feat(app): add backend information"
git push origin main --force