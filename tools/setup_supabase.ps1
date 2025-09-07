param(
  [string]$ProjectRef = "xrvntkufeisfdujjzxrn",
  [string]$SupabaseUrl = "https://xrvntkufeisfdujjzxrn.supabase.co",
  [string]$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhydm50a3VmZWlzZmR1amp6eHJuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwODM4MjQsImV4cCI6MjA3MjY1OTgyNH0.OO4uNfBMxqiYA2G1NbmIgzvFeHbuR2OnVSjL05KUH9E",
  [string]$ServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhydm50a3VmZWlzZmR1amp6eHJuIiwicm9zZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzA4MzgyNCwiZXhwIjoyMDcyNjU5ODI0fQ.N09cwQdwdeWe6ipC-faAv4SH7a-BhzAcZBNgvg6jgjI"
)

Write-Host "Installing Flutter dependencies..." -ForegroundColor Cyan
flutter pub add supabase_flutter

Write-Host "Ensuring Supabase CLI installed..." -ForegroundColor Cyan
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  iwr -useb https://cli.supabase.com/install/windows | iex
}

Write-Host "Linking Supabase project..." -ForegroundColor Cyan
supabase link --project-ref $ProjectRef

Write-Host "Setting Edge Function secrets..." -ForegroundColor Cyan
supabase secrets set `
  SUPABASE_URL=$SupabaseUrl `
  SUPABASE_SERVICE_ROLE_KEY=$ServiceKey

Write-Host "Deploying Edge Functions..." -ForegroundColor Cyan
supabase functions deploy sync-pull
supabase functions deploy sync-push

Write-Host "Done. Configure auth providers in the Supabase Dashboard if needed." -ForegroundColor Green
