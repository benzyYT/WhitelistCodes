import asyncio
import datetime
import os
import discord
from discord.ext import commands
import mysql.connector
import random
import string
from mysql.connector import MySQLConnection, Error
from dotenv import dotenv_values
from mysql.connector import RefreshOption
refresh = RefreshOption.LOG | RefreshOption.THREADS

vars = dotenv_values(".env")

config = {
    'user': vars["USERNAME"],
    'password': vars["PASSWORD"],
    'host': vars["HOSTNAME"],
    'database': vars["DATABASE"],
    'raise_on_warnings': True
}

whitelisted = vars["WHITELIST_IDS"]
syntax = vars["SYNTAX"]
TOKEN = vars["TOKEN"]

try:
    cnx = mysql.connector.connect(**config)
    cursor = cnx.cursor()
    print("MySQL connection established")
except Exception as e:
    print("Error at:")
    print(e)
    print()
    print("Exiting...")
    exit()
    
    




intents = discord.Intents().all()
client = commands.Bot(command_prefix='--', intents=intents)


def get_random_string(length):
    # choose from all lowercase letter
    letters = string.ascii_lowercase
    result_str = ''.join(random.choice(letters) for i in range(length))
    print("Random string of length", length, "is:", result_str)
    

@client.event
async def on_ready():
    print(f"\n")
    print(f"Bot | Status:   Bereit")
    print(f"Bot | ID:       {format(client.user.id)}")
    print(f"Bot | Name:     {format(client.user.name)}")
    print(f"Bot | Server:   {len(client.guilds)}")
    print(f"\n")
    print(f"Der Bot ist bereit genutzt zu werden")


@client.event 
async def on_command_error(ctx, error): 
    if isinstance(error, commands.CommandNotFound): 
        embed = discord.Embed(title="Command nicht gefunden", description=f'⛔ Diesen Command gibt es nicht', color=0xff0000) 
        await ctx.send(embed=embed)
    else:
        embed = discord.Embed(title="ERROR", description=f'⛔ Fehler:\n```{error}```', color=0xff0000) 
        await ctx.send(embed=embed)
        



@client.command()
async def create(ctx):
    now = datetime.datetime.now()
    dt = str(now.strftime("%d.%m"))
    tm = str(now.strftime("%H:%M Uhr"))
    if ctx.channel.id == 1034483669848563802:
        if f'{ctx.author.id}' not in whitelisted:
            embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ {ctx.author.name} hat keine Berechtigung um den `--create` Command auszuführen', color=0xff0000)
            embed.set_footer(text = f'{dt} {tm}')
            await ctx.send(embed=embed)
        else:
            letters = string.ascii_lowercase
            result_str = ''.join(random.choice(letters) for i in range(8))
            
            print("Neuer Joincode: --------", result_str, "-------- erstellt von", ctx.author.name, "|", ctx.author.id, "am", dt, "um", tm)
            with open('co.txt', 'a') as f:
                f.write(f'Neuer Joincode: -------- {result_str} -------- erstellt von {ctx.author.name} | {ctx.author.id} am {dt} um {tm}.')
                f.write('\n')
            
            
            embed = discord.Embed(title="Neuer Whitelistcode generiert", description="Der untenstehende Code kann genau 1x benutzt werden", color=0x00ff00)
            embed.add_field(name="Code", value=f"`{result_str}`", inline=False)
            embed.set_footer(text = f'{ctx.author.name} | {ctx.author.id} | {dt} {tm}')
            channel = client.get_channel(1034483381452423198)
            await channel.send(f'<@{ctx.author.id}>', embed=embed)
            await ctx.send(f'Dein Code wurde erstellt!')
            
            cnx.cmd_refresh(refresh)
            sql = ("INSERT INTO `codes` (`code`, `used`) VALUES (%s, %s);")
            val = (result_str, "0")
            cursor.execute(sql, val)
            cnx.commit()
    else:
        embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ Der Kanal `{ctx.channel}` ist nicht dafür da, den `--create` Command auszuführen', color=0xff0000)
        embed.set_footer(text = f'{dt} {tm}')
        await ctx.send(embed=embed)

@client.command()
async def getall(ctx):
    now = datetime.datetime.now()
    dt = str(now.strftime("%d.%m"))
    tm = str(now.strftime("%H:%M Uhr"))
    if ctx.channel.id == 1034483669848563802:
        if f'{ctx.author.id}' not in whitelisted:
            embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ {ctx.author.name} hat keine Berechtigung um den `--getall` Command auszuführen', color=0xff0000)
            embed.set_footer(text = f'{dt} {tm}')
            await ctx.send(embed=embed)
        else:
            cnx.cmd_refresh(refresh)
            sql = ("SELECT * FROM codes")
            cursor.execute(sql)
            result = cursor.fetchall()
            embed = discord.Embed(title="Alle Whitelistcodes", description=f"Hier sind alle Codes aufgelistet:\n```{result}```", color=0x00ff00)
            embed.add_field(name="Bedetungen", value="`0` = **unbenutzt**\n`1` = **benutzt**", inline=False)
            embed.set_footer(text = f'{dt} {tm}')
            await ctx.send(embed=embed)
            cnx.commit()
    else:
        embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ Der Kanal `{ctx.channel}` ist nicht dafür da, den `--getall` Command auszuführen', color=0xff0000)
        embed.set_footer(text = f'{dt} {tm}')
        await ctx.send(embed=embed)
        
@client.command()
async def invite(ctx):
    now = datetime.datetime.now()
    dt = str(now.strftime("%d.%m %H:%M Uhr"))
    if ctx.channel.id == 1034483669848563802:
        if ctx.author.id != 601336963424845832:
            embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ Nur `benzy#8191` kann diesen command ausführen.', color=0xff0000)
            embed.set_footer(text = f'{dt}')
            await ctx.send(embed=embed)
        else:
            await ctx.send(f'https://discord.com/api/oauth2/authorize?client_id={client.user.id}&permissions=8&scope=bot')
    else:
        embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ Der Kanal `{ctx.channel}` ist nicht dafür da, den `--invite` Command auszuführen', color=0xff0000)
        embed.set_footer(text = f'{dt}')
        await ctx.send(embed=embed)

@client.command()
async def cancel(ctx, *args):
    now = datetime.datetime.now()
    dt = str(now.strftime("%d.%m %H:%M Uhr"))
    if f'{ctx.author.id}' not in whitelisted:
        embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ {ctx.author.name} hat keine Berechtigung um den `--cancel` Command auszuführen', color=0xff0000)
        embed.set_footer(text = f'{dt}')
        await ctx.send(embed=embed)
    else:
        if len(args) > 1:
            embed = discord.Embed(title="Ungültige Anzahl", description=f'⛔ Bitte gib nur einen Code an', color=0xff0000)
            embed.set_footer(text = f'{dt}')
            await ctx.send(embed=embed)
        elif len(args) < 1:
            embed = discord.Embed(title="Ungültige Anzahl", description=f'⛔ Bitte gib nur einen Code an', color=0xff0000)
            embed.set_footer(text = f'{dt}')
            await ctx.send(embed=embed)
        else:
            data = args
            sql = ("UPDATE `codes` SET `used` = '1' WHERE `codes`.`code` = %s;")
            cursor.execute(sql, data)
            embed = discord.Embed(title="Code entwertet", description=f'Der untenstehende Code wurde entwertet und kann nicht mehr genutzt werden', color=0xff0000)
            embed.add_field(name='Code', value=f'`{args[0]}`', inline=False)
            embed.set_footer(text=f'{ctx.author.name} | {ctx.author.id} | {dt}')
            await ctx.send(embed=embed)
            cnx.commit()

@client.command()
async def remove(ctx, *args):
    now = datetime.datetime.now()
    dt = str(now.strftime("%d.%m %H:%M Uhr"))
    if f'{ctx.author.id}' not in whitelisted:
        embed = discord.Embed(title="Keine Berechtigung", description=f'⛔ {ctx.author.name} hat keine Berechtigung um den `--cancel` Command auszuführen', color=0xff0000)
        embed.set_footer(text = f'{dt}')
        await ctx.send(embed=embed)
    else:
        if len(args) > 1:
            embed = discord.Embed(title="Ungültige Anzahl", description=f'⛔ Bitte gib nur einen Identifier an', color=0xff0000)
            embed.set_footer(text = f'{dt}')
            await ctx.send(embed=embed)
        elif len(args) < 1:
            embed = discord.Embed(title="Ungültige Anzahl", description=f'⛔ Bitte gib nur einen Code an', color=0xff0000)
            embed.set_footer(text = f'{dt}')
            await ctx.send(embed=embed)
        else:
            data = args
            sql = ("DELETE FROM `codeswhitelist` WHERE `codeswhitelist`.`identifier` = %s;")
            cursor.execute(sql, data)
            embed = discord.Embed(title="Identifier entwertet", description=f'Der untenstehende Identifier wurde entwertet und kann nicht mehr joinen, ohne einen neuen Code!', color=0xff0000)
            embed.add_field(name='Identifier', value=f'`{args[0]}`', inline=False)
            embed.set_footer(text=f'{ctx.author.name} | {ctx.author.id} | {dt}')
            await ctx.send(embed=embed)
            cnx.commit()
            


client.run(TOKEN)
