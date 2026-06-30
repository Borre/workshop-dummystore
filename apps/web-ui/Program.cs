var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

builder.Services.AddHttpClient("Gateway", c =>
{
    c.BaseAddress = new Uri("http://gateway-api:9000");
});

var app = builder.Build();

app.Urls.Add("http://0.0.0.0:5000");

app.UseStaticFiles();
app.MapRazorPages();
app.MapBlazorHub();

app.MapGet("/health", () => "ok");

app.Run();
